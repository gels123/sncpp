local caoi = require "aoi.core"

local mt = {}
mt.__index = mt

-- 在 Marker 进入 Watcher 的 AOI 区域时会触发消息
aoiMode = {
    w = "w",        --观察者
    m = "m",        --被观察者
    wm = "wm",      --既是观察者亦是被观察者
    d = "d",        -- 丢弃/删除
}

--- 设置半径
function mt:setRadis(radis)
    assert(type(radis) == "number" and radis > 0, "setRadis invalid "..tostring(radis))
    self.radis = radis
    self.aoi:setRadis(radis)
end

--- 新增节点
--@id   对象id
--@mode 模式w/m/wm/d
--@pos  位置{x=,y=,z=}
--@v    速度{x=,y=,z=}
--@return boolean
function mt:add(id, mode, pos, v)
    assert(id and aoiMode[mode], "id or mode invalid id= " .. tostring(id) .." mode= " .. tostring(mode))
    local obj = self.tbl[id]
    if not obj then
        obj = {
            id = id,
            mode = mode,
            pos = {
                pos.x or 0,
                pos.y or 0,
                pos.z or 0
            },
        }
        if v then
            obj.v = {
                v.x or 0,
                v.y or 0,
                v.z or 0,
            }
        end
        self.tbl[id] = obj
        self.aoi:add(obj.id, obj.mode, obj.pos[1], obj.pos[2], obj.pos[3])
        return true
    end
    return false
end

--- 删除节点
--@id   对象id
--@return boolean
function mt:delete(id)
    local obj = self.tbl[id]
    if obj then
        obj.mode = aoiMode.d
        self.aoi:delete(obj.id, obj.mode, obj.pos[1], obj.pos[2], obj.pos[3])
        self.tbl[id] = nil
        return true
    end
    return false
end

--- 更新节点坐标
--@int 节点id
--@float x
--@float y
--@float z
function mt:update(id, x, y, z)
    local obj = self.tbl[id]
    if obj then
        obj.pos[1] = x or 0
        obj.pos[2] = y or 0
        obj.pos[3] = z or 0
        self.aoi:update(obj.id, obj.mode, obj.pos[1], obj.pos[2], obj.pos[3])
    end
end

--- 获取节点信息
--@int 节点id
--@return table
function mt:get(id)
    return self.tbl[id]
end

--- 主动获取aoi信息
function mt:message()
    return self.aoi:message()
end

local M = {}

function M.new(radis)
    --print("aoi.new radis=", radis)
    local obj = {}
    obj.aoi = caoi()
    obj.tbl = {}
    obj.radis = radis or 10
    obj.aoi:setRadis(obj.radis)
    return setmetatable(obj, mt)
end

return M