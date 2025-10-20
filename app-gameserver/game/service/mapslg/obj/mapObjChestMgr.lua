--[[
-- 地图宝箱刷新和管理
--]]
local skynet = require "skynet"
local skynetenv = require "skynetenv"
local mapConf = require "mapConf"
local Random = require "random"
local mapCenter = require("mapCenter"):shareInstance()
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjChestMgr = class("mapObjChestMgr", mapRefreshMgr)

function mapObjChestMgr:ctor()
	self.super.ctor(self)

	-- 区域地图对象关联
	self.areaObjs = {}

	-- 需要刷新的类型
	self.refreshTypes = {
		-- [mapConf.chest_type.radar_npc] = true,
	}
end

-- override
function mapObjChestMgr:init()
	-- self.super.init(self)
end

-- override
function mapObjChestMgr:init_over()
	-- self:doSupplyRefresh()
end

-- 增加对象
function mapObjChestMgr:add_object(obj)
	self.super.add_object(self, obj)

	-- 更新区域地图对象关联
	local x, y = obj:get_position()
	local areaid = mapCenter.mapMaskMgr:get_areaid(x, y)
	local cfg = obj:get_config()
	local subtype = cfg.Type
	if not self.areaObjs[areaid] then
		self.areaObjs[areaid] = {}
	end
	if not self.areaObjs[areaid][subtype] then
		self.areaObjs[areaid][subtype] = {}
	end
	self.areaObjs[areaid][subtype][obj:get_objectid()] = obj
end

-- 删除对象
function mapObjChestMgr:remove_object(obj)
	self.super.remove_object(self, obj)

	-- 更新区域地图对象关联
	local x, y = obj:get_position()
	local areaid = mapCenter.mapMaskMgr:get_areaid(x, y)
	local cfg = obj:get_config()
	local subtype = cfg.Type
	if self.areaObjs[areaid] and self.areaObjs[areaid][subtype] then
		self.areaObjs[areaid][subtype][obj:get_objectid()] = nil
	end
end

return mapObjChestMgr
