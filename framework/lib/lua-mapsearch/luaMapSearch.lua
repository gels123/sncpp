--[[
    寻路
    eg:
        local luaMapSearch = require("cpp.luaMapSearch")
        local ms = luaMapSearch.new()
        ms:init(1, 100)
        local path = ms:findPath(0, 0, 99, 99)
]]
local mapSearch = require "mapSearch"

local mt = {}
mt.__index = mt

function mt:testFun(a, b)
    return self.ms:testFun(a, b)
end

-- 初始化
function mt:init(mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile)
    return self.ms:init(mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile)
end

-- 寻路
function mt:findPath(x1, y1, x2, y2, aid, speed, railwayTime)
    return self.ms:findPath(x1-1, y1-1, x2-1, y2-1, aid, speed, railwayTime)
end

-- 设置/取消铁路站点归属
function mt:setRailwayAid(x, y, aid)
    return self.ms:setRailwayAid(x-1, y-1, aid or 0)
end

-- 设置/取消友盟关系, isadd=[1设置, 0取消]
function mt:setFriendAid(aid1, aid2, isadd)
    return self.ms:setFriendAid(aid1, aid2, isadd)
end

local M = {}
function M.new()
    local obj = {}
    obj.ms = mapSearch()
    return setmetatable(obj, mt)
end

return M

