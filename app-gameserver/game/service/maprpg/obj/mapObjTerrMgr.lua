--[[
-- 地图建领地建筑管理
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local mapCenter = require("mapCenter"):shareInstance()
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjTerrMgr = class("mapObjTerrMgr", mapRefreshMgr)

function mapObjTerrMgr:ctor()
    self.super.ctor(self)

    self.typeobjs = {}
end

-- 增加对象
function mapObjTerrMgr:add_object(obj)
    self.super.add_object(self, obj)

    local objid, type, subtype = obj:get_objectid(), obj:getMapType(), obj:getSubMapType() or 0
    if not self.typeobjs[type] then
        self.typeobjs[type] = {}
    end
    if not self.typeobjs[type][subtype] then
        self.typeobjs[type][subtype] = {}
    end
    self.typeobjs[type][subtype][objid] = obj
end

-- 删除对象
function mapObjTerrMgr:remove_object(obj)
    self.super.remove_object(self, obj)

    local objid, type, subtype = obj:get_objectid(), obj:getMapType(), obj:getSubMapType() or 0
    if self.typeobjs[type] and self.typeobjs[type][subtype] then
        self.typeobjs[type][subtype][objid] = nil
    end
end

function mapObjTerrMgr:pack_type_objects(v, type, subtype, ret)
    if self.typeobjs[type] and self.typeobjs[type][subtype] then
        local zoneconnect = get_static_config().zoneconnect
        for objid,obj in pairs(self.typeobjs[type][subtype]) do
            if type == mapConf.object_type.checkpoint or type == mapConf.object_type.wharf then
                if zoneconnect[objid] then
                    local zoneId1, zoneId2 = zoneconnect[objid].zone1, zoneconnect[objid].zone2
                    if zoneId1 and zoneId2 and v.OpenRegionTotalID[zoneId1] and v.OpenRegionTotalID[zoneId2] then
                        ret[objid] = obj:pack_message_data()
                        ret[objid].groupId = v.groupId
                    end
                end
            else
                local zoneId = mapCenter.mapMaskMgr:get_subzone(obj:get_position())
                if zoneId and v.OpenRegionTotalID[zoneId] then
                    ret[objid] = obj:pack_message_data()
                    ret[objid].groupId = v.groupId
                end
            end
        end
    end
end

return mapObjTerrMgr
