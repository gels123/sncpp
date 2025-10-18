--[[
    aoi-十字链表之实现 (支持非固定视野范围,但视野不宜过大、对象不宜小范围过于集中,若视野变化则删原观察者再创观察者,坐标变更时遍历链表, 数据量大且变化平凡时, 新能性能较差)
    eg:
        if not aoiCenter.aoi then
            aoiCenter.aoi = require("aoi-link").new(1000, 1000)
        end
        local obj = {id = 101, pos = {x=5, z=5}}
        local enter, leave = aoiCenter.aoi:update_entity(obj.id, obj.pos)
        gLog.d("000000=", table2string(enter), table2string(leave))
        local obj = {id = 102, pos = {x=6, z=6}}
        local enter, leave = aoiCenter.aoi:update_entity(obj.id, obj.pos)
        gLog.d("111111=", table2string(enter), table2string(leave))
        local obj = {id = 103, pos = {x=10, z=10}}
        local enter, leave = aoiCenter.aoi:update_trigger(obj.id, obj.pos, 10)
        gLog.d("222222=", table2string(enter), table2string(leave))
        local tab = aoiCenter.aoi:get_witness(101)
        gLog.d("333333=", table2string(tab))
        local tab = aoiCenter.aoi:get_visible(103)
        gLog.d("444444=", table2string(tab))
]]
local gLog = require "newLog"
local aoilink = require "aoilink"

local mt = {}
mt.__index = mt

--- 更新被观察者
function mt:update_entity(objid, pos)
    assert(objid and pos and pos.x and pos.z)
    local obj = self.tbl[objid]
    if obj then
        if obj.x ~= pos.x or obj.z ~= pos.z then
            obj.x = pos.x or 0
            obj.z = pos.z or 0
            local enter, leave = self.aoi:move_entity(obj.ud, obj.x, obj.z)
            --gLog.dump(obj, "aoi-link update_entity move_entity=")
            return enter, leave
        end
    else
        obj = {
            objid = objid,
            x = pos.x or 0,
            z = pos.z or 0,
            ud = nil,
        }
        local r, ud, enter, leave = self.aoi:create_entity(obj.objid, obj.x, obj.z)
        if r < 0 then
            gLog.w("aoi-link update_entity fail", objid, r, ud)
            return
        end
        obj.ud = ud
        self.tbl[objid] = obj
        --gLog.dump(obj, "aoi-link update_entity create_entity=")
        return enter, leave
    end
end

--- 更新观察者
--@range 视野范围
function mt:update_trigger(objid, pos, range)
    assert(objid and pos and pos.x and pos.z)
    local obj = self.tbl[objid]
    if obj then
        if obj.x ~= pos.x or obj.z ~= pos.z then
            obj.x = pos.x or 0
            obj.z = pos.z or 0
            local enter, leave = self.aoi:move_trigger(obj.ud, obj.x, obj.z)
            --gLog.dump(obj, "aoi-link update_trigger move_trigger=")
            return enter, leave
        end
    else
        obj = {
            objid = objid,
            x = pos.x or 0,
            z = pos.z or 0,
            range = range or 1,
            ud = nil,
        }
        local r, ud, enter, leave = self.aoi:create_trigger(obj.objid, obj.x, obj.z, range)
        if r < 0 then
            gLog.w("aoi-link update_trigger fail", objid, r, ud)
            return
        end
        obj.ud = ud
        self.tbl[objid] = obj
        --gLog.dump(obj, "aoi-link update_trigger create_trigger=")
        return enter, leave
    end
end

--- 删除被观察者
function mt:delete_entity(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        self.tbl[objid] = nil
        local enter, leave = self.aoi:delete_entity(obj.ud)
        return enter, leave
    end
end

--- 删除观察者
function mt:delete_trigger(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        self.tbl[objid] = nil
        local enter, leave = self.aoi:delete_trigger(obj.ud)
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
        return self.aoi:get_witness(obj.ud)
    end
end

--- 获取可视对象
function mt:get_visible(objid)
    assert(objid)
    local obj = self.tbl[objid]
    if obj then
        return self.aoi:get_visible(obj.ud)
    end
end

local M = {}

--- 创建aoi
--@width    地图宽x
--@height   地图高z
function M.new(width, height)
    assert(width and width > 0 and height and height > 0)
    local obj = {}
    obj.aoi = aoilink(width, height)
    obj.tbl = {}
    obj.width = width
    obj.height = height
    return setmetatable(obj, mt)
end

return M