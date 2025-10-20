--[[
	地图视野管理
--]]
local skynet = require "skynet"
local mapAoiC = require "mapAoi"
local mapConf = require "mapConf"
local interaction = require "interaction"
local svrconf = require "svrconf"
local mapWatcher = require("mapWatcher")
local mapCenter = require("mapCenter"):shareInstance()
local mapAoiMgr = class("mapAoiMgr")

function mapAoiMgr:ctor()
	-- 地图对象AOI列表
	self.aoiList = {}
	-- 观察者
	self.watcherList = {}
end

-- 初始化
function mapAoiMgr:init(width, height, confs)
	--gLog.d("mapAoiMgr:init", width, height, table2string(confs))
	assert(width and height and type(confs) == "table")
	self.width = width
	self.height = height
	self.confs = confs
	
	for k, v in ipairs(confs) do
		self.aoiList[k] = mapAoiC.new(width, height, v)
	end
end

-- 增加对象
function mapAoiMgr:add_object(obj, isInit)
	for k, v in pairs(self.aoiList) do
		v:add_object(obj, isInit)
	end
end

-- 删除对象
function mapAoiMgr:remove_object(obj, more)
	for k, v in pairs(self.aoiList) do
		v:remove_object(obj, more)
	end
end

-- 更新对象, 推送客户端
function mapAoiMgr:update_object(obj)
	--gLog.i("mapAoiMgr:update_object1")
	for k, v in pairs(self.aoiList) do
		v:update_object(obj)
	end
	--gLog.i("mapAoiMgr:update_object2")
end

--获取观察者
function mapAoiMgr:get_watcher(playerid)
	if not self.watcherList[playerid] then
		self.watcherList[playerid] = mapWatcher.new(playerid)
	end
	return self.watcherList[playerid]
end

--移除观察者
function mapAoiMgr:remove_watcher(playerid)
	gLog.d("mapAoiMgr:remove_watcher", playerid)
	local watcher = self.watcherList[playerid]
	if watcher then
		for k, v in pairs(self.aoiList) do
			v:remove_watcher(watcher)
		end
	end
	self.watcherList[playerid] = nil
end

--更新观察者, 获取地图对象数据
--ispost  #是否下发无归属的指挥所
function mapAoiMgr:reqmapinfo(kid, playerid, x, y, radius, ispost)
	gLog.d("mapAoiMgr:reqmapinfo", kid, playerid, x, y, radius, ispost)
	--参数校验
	if not playerid or not x or not y or not radius then
		gLog.e("mapAoiMgr:reqmapinfo error1", kid, playerid, x, y, radius)
		return {code = global_code.error_param,}
	end
	if x > mapConf.map_size then x = mapConf.map_size end
	if y > mapConf.map_size then y = mapConf.map_size end
	--获取观察者
	local watcher = self:get_watcher(playerid)
	--根据直径获取aoi等级
	local lv, slv = nil, nil
	for i = 1, #self.confs, 1 do
		if radius <= self.confs[i].offsetMax then
			lv, slv = i, self.confs[i].slv
			break
		end
	end
	if not lv then
		lv, slv = #self.confs, self.confs[#self.confs].slv
	end
	if slv ~= 3 then
		ispost = nil
	end
	--
	local oldx, oldy, oldlv, oldispost = watcher:get_position()
	gLog.d("mapAoiMgr:reqmapinfo old=", oldx, oldy, oldlv, oldispost, ispost)
	if oldx and oldy and oldlv then
		if lv == oldlv and not (ispost and not oldispost) then
			local ogx, ogy = self.aoiList[lv]:to_grid_xy(oldx, oldy)
			local gx, gy = self.aoiList[lv]:to_grid_xy(x, y)
			if ogx == gx and ogy == gy then
				--还在同一个九宫格 不做处理
				return {code = global_code.success,}
			else
				self.aoiList[oldlv]:remove_watcher(watcher)
			end
		else
			self.aoiList[oldlv]:remove_watcher(watcher)
		end
	end
	watcher:set_position(x, y, lv, kid, ispost)
	self.aoiList[lv]:add_watcher(watcher)

	--地图对象
	local newgrids = {}
	local addgrids, delgrids = self.aoiList[lv]:get_watcher_grids(watcher, lv)
	for _, grid in pairs(addgrids) do
		table.insert(newgrids, {
			gridid = grid:get_key(),
			objs = grid:pack_message_data(slv, ispost)
		})
	end
	--gLog.dump(delgrids, "mapAoiMgr:reqmapinfo delgrids="..lv, 3)

	--下发数据
	return {
		code = global_code.success,
		kid = svrconf.kid,
		lv = lv,
		newgrids = newgrids,
		delgrids = delgrids,
	}
end

return mapAoiMgr