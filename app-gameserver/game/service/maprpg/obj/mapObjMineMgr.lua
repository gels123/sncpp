--[[
-- 地图矿点刷新和管理
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local Random = require "random"
local mapCenter = require("mapCenter"):shareInstance()
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjMineMgr = class("mapObjMineMgr", mapRefreshMgr)

function mapObjMineMgr:ctor()
	self.super.ctor(self)

	-- 区域地图对象关联
	self.chunckObjs = {}

	-- 刷新配置
	self.refreshPool = {}

	-- 需要刷新的类型
	self.refreshTypes = {
		[mapConf.mine_type.food] = true,
		[mapConf.mine_type.water] = true,
	}
end

-- override
function mapObjMineMgr:init()
	gLog.d("mapObjMineMgr:init")
	self.super.init(self)

	-- 刷新配置
	self:refresh_mine_pool()
end

-- override
function mapObjMineMgr:init_over()
	self:doSupplyRefresh(true)
end

-- 获取补刷计时器间隔
function mapObjMineMgr:getSupplyTimerInterval()
	local reftime = get_static_config().worldmap_globals.MineFullTime
	return Random.Get(reftime[1], reftime[2])
end

-- 获取重刷计时器间隔
function mapObjMineMgr:getResetTimerInterval()
	return get_static_config().worldmap_globals.MineClearTime
end

-- 执行补刷
function mapObjMineMgr:doSupplyRefresh(isInit)
	gLog.i("mapObjMineMgr:doSupplyRefresh enter")
	local sq = mapCenter:getSq("mapObjMineMgr")
	sq(function ()
		gLog.i("==mapObjMineMgr:doSupplyRefresh begin==")
		for chunckx=1,mapConf.map_block_line,1 do
			for chuncky=1,mapConf.map_block_line,1 do
				xpcall(function ()
					local chunckid = mapUtils.get_chunck_id2(chunckx, chuncky)
					self:refresh_chunck_mine(chunckid)
					if not isInit then
						skynet.sleep(1)
					end
				end, svrFunc.exception)
			end
		end
		gLog.i("==mapObjMineMgr:doSupplyRefresh end==")
	end)
end

-- 执行重刷
function mapObjMineMgr:doResetRefresh()
	gLog.i("mapObjMineMgr:doResetRefresh enter")
	local sq = mapCenter:getSq("mapObjMineMgr")
	sq(function ()
		gLog.i("==mapObjMineMgr:doSupplyRefresh begin==")
		local ids = {}
		for chunckx=1,mapConf.map_block_line,1 do
			for chuncky=1,mapConf.map_block_line,1 do
				local chunckid = mapUtils.get_chunck_id2(chunckx, chuncky)
				table.insert(ids, chunckid)
			end
		end
		--随机打乱
		ids = Random.GetSets(ids)
		while(#ids > 0) do
			local chunckid = table.remove(ids)
			if not chunckid then
				break
			end
			xpcall(function ()
				self:reset_chunck(chunckid)
			end, svrFunc.exception)
			skynet.sleep(10)
		end
		gLog.i("==mapObjMineMgr:doSupplyRefresh end==")
	end)
end

-- 重刷区域
function mapObjMineMgr:reset_chunck(chunckid)
	local area = get_static_config().area
	local chunckLv = area[chunckid] and area[chunckid].Level --地块等级
	if chunckLv and self.refreshPool[chunckLv] then
		for subMapType,v in pairs(self.refreshPool[chunckLv]) do
			local temp = self:get_chunck_objs(chunckid, subMapType)
			local count = table.nums(temp)
			if count > 0 then
				self:remove_mine(chunckid, subMapType, count)
			end
		end
		self:refresh_chunck_mine(chunckid)
	end
end

--刷新怪物池
function mapObjMineMgr:refresh_mine_pool()
	self.refreshPool = {}
	local resource_refresh = get_map_config().resource_refresh
	for chunckLv,v in pairs(resource_refresh) do
		for subMapType,cfg in pairs(v) do
			if not self.refreshPool[chunckLv] then
				self.refreshPool[chunckLv] = {}
			end
			if not self.refreshPool[chunckLv][subMapType] then
				self.refreshPool[chunckLv][subMapType] = {
					num = cfg.Num,
					totalRate = 0,
					random = {},
				}
			end
			local totalRate = 0
			local maxlv = 50
			for i = 1, maxlv do
				local key = "Lv" .. i
				totalRate = totalRate + (cfg[key] or 0)
			end
			self.refreshPool[chunckLv][subMapType].totalRate = totalRate
			for i = 1, maxlv do
				local key = "Lv" .. i
				local rate = (cfg[key] or 0)
				if rate > 0 then
					table.insert(self.refreshPool[chunckLv][subMapType].random, {lv = i, rate = rate})
				end
			end
		end
	end
	gLog.dump(self.refreshPool, "mapObjMineMgr:refresh_mine_pool refreshPool=", 10)
end

--刷新区域内矿
function mapObjMineMgr:refresh_chunck_mine(chunckid)
	local area = get_static_config().area
	local chunckLv = area[chunckid] and area[chunckid].Level --地块等级
	if chunckLv and self.refreshPool[chunckLv] then
		for subMapType,v in pairs(self.refreshPool[chunckLv]) do
			if self.refreshPool[chunckLv][subMapType] then
				local temp = self:get_chunck_objs(chunckid, subMapType)
				local count = table.nums(temp)
				-- gLog.d("mapObjMineMgr:refresh_chunck_mine chunckid=", chunckid, "subMapType=", subMapType, "num=", self.refreshPool[chunckLv][subMapType].num, "count=", count)
				if self.refreshPool[chunckLv][subMapType].num > count then
					--需求数量大于当前数量  添加活物
					self:born_mine(chunckLv, subMapType, chunckid, self.refreshPool[chunckLv][subMapType].num - count)
				elseif count > self.refreshPool[chunckLv][subMapType].num then
					--当前数量大于需求数量  删除活物
					self:remove_mine(chunckid, subMapType, count - self.refreshPool[chunckLv][subMapType].num)
				end
			end
		end
	end
end

--生成随机怪物
function mapObjMineMgr:born_mine(chunckLv, subMapType, chunckid, num)
	local refreshCfg = self.refreshPool[chunckLv] and self.refreshPool[chunckLv][subMapType]
	if refreshCfg then
		local k,v = svrFunc.getRandomIndex(refreshCfg.random, "rate", refreshCfg.totalRate)
		if not v then
			gLog.e("mapObjMineMgr:born_mine error1", refreshCfg)
			return
		end
		local cfg = get_static_config().mine[subMapType][v.lv]
		if not cfg then
			gLog.e("mapObjMineMgr:born_mine error1", subMapType, chunckid, v.lv)
			return
		end
		local w, h = mapUtils.get_obj_size(mapConf.object_type.mine)
		local bnum = num
		while bnum > 0 do
			local pos = mapCenter.mapMaskMgr:random_spacepos_by_chunckid(chunckid, w, h)
			if not pos or not pos[1] or not pos[2] then --该区域都没有位置了 退出
				gLog.e("mapObjMineMgr:born_mine error2", subMapType, chunckid, v.lv)
				break
			end
			local x, y = pos[1], pos[2]
			local object = require("mapObjInterface").create_mine(cfg, x, y)
			if not object then
				gLog.e("mapObjMineMgr:born_mine error3", subMapType, chunckid, v.lv)
			end
			bnum = bnum - 1
		end
	end
end

function mapObjMineMgr:remove_mine(chunckid, subMapType, num)
	if num <= 0 then
		return
	end
	local removeobjmap = {}
	local n = num
	local temp = self:get_chunck_objs(chunckid, subMapType)
	if temp then
		for objectid, _  in pairs(temp) do
			local object = mapCenter.mapObjectMgr:get_object(objectid)
			if object and object:canRemove() then
				removeobjmap[objectid] = object
				n = n - 1
			else
				gLog.e("mapObjMineMgr:remove_mine error", chunckid, subMapType, num, "objectid=", objectid)
				temp[objectid] = nil
			end
			if n <= 0 then
				break
			end
		end
	end
	--执行删除
	for _,object in pairs(removeobjmap) do
		mapCenter.mapObjectMgr:remove_object(object)
	end
end

function mapObjMineMgr:get_chunck_objs(chunckid, subtype)
	return self.chunckObjs[chunckid] and self.chunckObjs[chunckid][subtype] or {}
end

-- 增加对象
function mapObjMineMgr:add_object(obj)
	self.super.add_object(self, obj)

	-- 更新区块地图对象关联
	local x, y = obj:get_position()
	local chunckid = mapUtils.get_chunck_id(x, y)
	local subtype = obj:getSubMapType()
	-- gLog.d("mapObjMineMgr:add_object x=", x, "y=", y, "chunckid=", chunckid, "type=", obj:getMapType(), "subtype=", subtype)
	if not self.chunckObjs[chunckid] then
		self.chunckObjs[chunckid] = {}
	end
	if not self.chunckObjs[chunckid][subtype] then
		self.chunckObjs[chunckid][subtype] = {}
	end
	if not self.chunckObjs[chunckid][subtype] then
		self.chunckObjs[chunckid][subtype] = {}
	end
	self.chunckObjs[chunckid][subtype][obj:get_objectid()] = obj

	-- for debug
	-- local temp = self:get_chunck_objs(chunckid, subtype)
	-- gLog.d("mapObjMineMgr:add_object end=", "chunckid=", chunckid, "type=", obj:getMapType(), "subtype=", subtype, table.nums(temp))
end

-- 删除对象
function mapObjMineMgr:remove_object(obj)
	self.super.remove_object(self, obj)

	-- 更新区域地图对象关联
	local x, y = obj:get_position()
	local chunckid = mapUtils.get_chunck_id(x, y)
	local subtype = obj:getSubMapType()
	if self.chunckObjs[chunckid] and self.chunckObjs[chunckid][subtype] then
		self.chunckObjs[chunckid][subtype][obj:get_objectid()] = nil
	end
end

return mapObjMineMgr
