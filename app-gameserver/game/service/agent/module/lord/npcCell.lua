--[[
    单个npc
]]
local skynet = require("skynet")
local npcCell = class("npcCell")

function npcCell:ctor(data)
    self.data = data
end

function npcCell:getData()
    return self.data
end

function npcCell:setAttr(key, value)
    self.data[key] = value
end

function npcCell:getAttr(key)
    return self.data[key]
end

return npcCell
