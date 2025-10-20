--[[
-- 九宫格逻辑
--]]
local mapGridCellC = require "mapGridCell"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local gateLib = require "gateLib"
local mapAoi = class("mapAoi")
local inspect = require "server.base.inspect"
-- 6 3 7
-- 2 9 4
-- 5 1 8
--方向偏移值
local deltaXY = {
	mapUtils.get_coord_id(0, -1),
	mapUtils.get_coord_id(-1, 0),
	mapUtils.get_coord_id(0, 1),
	mapUtils.get_coord_id(1, 0),
	mapUtils.get_coord_id(-1, -1),
	mapUtils.get_coord_id(-1, 1),
	mapUtils.get_coord_id(1, 1),
	mapUtils.get_coord_id(1, -1),
	mapUtils.get_coord_id(0, 0),
}

function mapAoi:ctor(width, height, conf)
	-- gLog.d("mapAoi:ctor", width, height, table2string(conf))
	assert(width and height and conf and conf.offset and type(conf.mapTypes) == "table")
	self.width = width
	self.height = height
	self.conf = conf
	self.grids = {} 			--格子

	--初始化
	self:init()
end

--初始化
function mapAoi:init()
	local nx = math.ceil(self.width / self.conf.offset)
	local ny = math.ceil(self.height / self.conf.offset)
	for x = 1, nx do
		for y = 1, ny do
			local key = mapUtils.get_coord_id(x, y)
			self.grids[key] = mapGridCellC.new(key)
		end		
	end
end

function mapAoi:get_grid_key(x, y)
	return mapUtils.get_coord_id(self:to_grid_xy(x, y))
end

function mapAoi:to_grid_xy(x, y)
	return math.ceil(x / self.conf.offset), math.ceil(y / self.conf.offset)
end

function mapAoi:to_world_xy(x, y)
	return (x - 1) * self.conf.offset + 1, (y - 1) * self.conf.offset + 1
end

function mapAoi:get_offset()
	return self.conf.offset
end

function mapAoi:get_width()
	return self.width
end

function mapAoi:get_height()
	return self.height
end

function mapAoi:get_grid(x, y)
	local key = self:get_grid_key(x, y)
	return self.grids[key]
end

--遍历九宫格
function mapAoi:walk_grids(x, y, func)
	local key = self:get_grid_key(x, y)
	for _, v in pairs(deltaXY) do
		local grid = self.grids[key + v]
		if grid then
			func(grid)
		end
	end
end

--获取九宫格所有观察者
function mapAoi:get_object_watcher(obj)
	if not self.conf.mapTypes[obj:getMapType()] then
		return
	end
	local watchers = {}
	local x, y = obj:get_position()
	self:walk_grids(x, y, function(grid)
		for k, v in pairs(grid:get_watchers()) do
			watchers[k] = v
		end
	end)
	return watchers
end

--获取观察者观察的所有格子
function mapAoi:get_watcher_grids(watcher, lv)
	local grids = {}
	local x, y = watcher:get_position()
	self:walk_grids(x, y, function(grid)
		grids[grid:get_key()] = grid
	end)
	return watcher:judge_viewgrid(grids)
end

--获取坐标点为中心，半径range的所有格子
function mapAoi:get_grids(x, y, range)
	local width = self:get_width()
	local height = self:get_height()
	local offset = self:get_offset()
	local r = math.floor(range / offset)
	range = r * offset
	--修正中心点坐标，使搜索范围不会越界
	if x - range < 0 then
		x = range
	elseif x + range > width then
		x = width - range
	end

	if y - range < 0 then
		y = range
	elseif y - range > height then
		y = height - range
	end

	local key = self:get_grid_key(x, y)
	local grids = {}
	local i, j
	for i = 0-r, r do
		for j = 0-r, r do
			local offset = mapUtils.get_coord_id(i, j)
			local grid = self.grids[key + offset]
			if grid then
				grids[grid:get_key()] = grid
			end
		end
	end
	return grids, x, y
end

function mapAoi:add_object(obj, isInit)
	-- gLog.d("mapAoi:add_object", obj:get_objectid(), obj:getMapType(), obj:getSubMapType(), obj:get_position())
	if not self.conf.mapTypes[obj:getMapType()] then
		return
	end
	local x, y = obj:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("mapAoi:add_object errror", x, y)
		return
	end
	grid:add_object(obj)

	-- 推送客户端
	local svruids = self:get_pos_watcher_uids(x, y)
	if next(svruids) then
		local msg = {gridid = grid:get_key(), obj = obj:pack_message_data()}
		for kid, uids in pairs(svruids) do
			gateLib:sendMsgToPlayers(kid, uids, "updatemapobject", msg)
		end
	end
end

function mapAoi:remove_object(obj, more)
	--gLog.d("mapAoi:remove_object", obj:get_objectid(), obj:get_field("x"), obj:get_field("y"))
	if not self.conf.mapTypes[obj:getMapType()] then
		if svrconf.DEBUG and self.conf.lv == 1 then
			gLog.e("mapAoi:remove_object fail", obj:get_objectid(), obj:getMapType(), obj:getSubMapType())
		end
		return
	end
	local x, y = obj:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("mapAoi:add_object error", x, y)
		return
	end
	grid:remove_object(obj)

	-- 推送客户端
	local svruids = self:get_pos_watcher_uids(x, y)
	if next(svruids) then
		local msg = {gridid = grid:get_key(), objid = obj:get_objectid()}
		if more then
			table.merge(msg, more)
		end
		for kid, uids in pairs(svruids) do
			gateLib:sendMsgToPlayers(kid, uids, "removemapobject", msg)
		end
	end
end

function mapAoi:update_object(obj)
	if not self.conf.mapTypes[obj:getMapType()] then
		return
	end
	local x, y = obj:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("mapAoi:update_object error", x, y)
		return
	end
	-- 推送客户端
	local svruids = self:get_pos_watcher_uids(x, y)
	if next(svruids) then
		local data = obj:pack_message_data()
		if data.type == mapConf.object_type.commandpost and self.conf.slv >= 3 and not data.isAct then
			local msg = {gridid = grid:get_key(), objid = data.objid}
			for kid, uids in pairs(svruids) do
				gateLib:sendMsgToPlayers(kid, uids, "removemapobject", msg)
			end
		else
			local msg = {gridid = grid:get_key(), obj = data}
			for kid, uids in pairs(svruids) do
				gateLib:sendMsgToPlayers(kid, uids, "updatemapobject", msg)
				--gLog.i("mapAoi:update_object info",inspect(msg))
			end
		end
	end
end

function mapAoi:get_pos_watcher_uids(x, y)
	local svruids = {}
	self:walk_grids(x, y, function(grid)
		local watchers = grid:get_watchers()
		if next(watchers) then
			for k, v in pairs(watchers) do
				local kid, uid = v:get_serverid(), v:get_key()
				if not svruids[kid] then
					svruids[kid] = {}
				end
				table.insert(svruids[kid], uid)
			end
		end
	end)
	return svruids
end

function mapAoi:add_watcher(watcher)
	local x, y = watcher:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("mapAoi:add_watcher error", watcher:get_key(), x, y)
		return
	end
	grid:add_watcher(watcher)
end

function mapAoi:remove_watcher(watcher)
	local x, y = watcher:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("mapAoi:remove_watcher error1", watcher:get_key(), x, y)
		return
	end
	grid:remove_watcher(watcher)
	-- fix可能潜在的内存泄漏
	for k,v in pairs(self.grids) do
		if v.watchers[watcher:get_key()] then
			gLog.e("mapAoi:remove_watcher error2", watcher:get_key(), v:get_key())
			v:remove_watcher(watcher)
		end
	end
end

return mapAoi