--[[
    单个buff
]]
local skynet = require("skynet")
local buffCell = class("buffCell")

function buffCell:ctor(data)
    self.data = data
end

function buffCell:setData(data)
    self.data = data
end

function buffCell:getData()
    return self.data
end

function buffCell:setAttr(key, value)
    self.data[key] = value
end

function buffCell:getAttr(key)
    return self.data[key]
end

return buffCell
