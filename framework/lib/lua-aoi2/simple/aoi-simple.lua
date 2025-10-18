--[[
    aoi-九宫格之实现 (只支持固定视野)
]]
local aoisimple = require "aoisimple"

local mt = {}
mt.__index = mt

--- 添加对象
--@layer 0=普通对象(被观察者) 1=怪物对象(观察者&被观察者) 2=玩家对象(观察者&被观察者) 3=玩家对象(观察者)
function mt:add(objid, pos, layer)
    assert(objid and pos and pos.x and pos.z and layer)
    local obj = self.tbl[objid]
    if not obj then
        obj = {
            objid = objid,
            x = pos.x or 0,
            z = pos.z or 0,
            layer = layer,
            id = nil, --c层id
        }
        local id, enter, leave = self.aoi:aoi_enter(obj.objid, obj.x, obj.z, layer)
        if id < 0 then
            gLog.w("aoi-simple add fail", obj.objid, id)
            return
        end
        obj.id = id
        self.tbl[objid] = obj
        return enter, leave
    end
    gLog.w("aoi-simple add fail", obj.id, obj.objid)
end

--- 删除对象
function mt:delete(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        local enter, leave = self.aoi:aoi_leave(obj.id)
        self.tbl[objid] = nil
        return enter, leave
    end
end

--- 更新对象坐标
function mt:update(objid, pos)
    assert(objid and pos and pos.x and pos.z)
    local obj = self.tbl[objid]
    if obj and (obj.x ~= pos.x or obj.z ~= pos.z) then
        obj.x = pos.x or 0
        obj.z = pos.z or 0
        local r, enter, leave = self.aoi:aoi_update(obj.id, obj.x, obj.z)
        if r < 0 then
            gLog.w("aoi-simple update fail", r)
            return
        end
        return enter, leave
    end
end

--- 获取对象信息
function mt:get(objid)
    return self.tbl[objid]
end

--- 获取目击对象
function mt:get_witness(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        return self.aoi:get_witness(obj.id)
    end
end

--- 获取可视对象
function mt:get_visible(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        return self.aoi:get_visible(obj.id)
    end
end

local M = {}

--- 创建aoi
--@width    地图宽x
--@height   地图高z
--@cell     地图格宽高
--@range    视野范围
function M.new(width, height, cell, range)
    assert(width and height and cell and range)
    local obj = {}
    obj.aoi = aoisimple(width, height, cell, range)
    obj.tbl = {}
    obj.width = width
    obj.height = height
    obj.cell = cell
    obj.range = range
    return setmetatable(obj, mt)
end

return M