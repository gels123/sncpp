--[[
    寻路服务中心
]]
local skynet = require("skynet")
local mc = require("skynet.multicast")
local Grid = require ("grid")
local PathFinder = require ("pathFinder")
local serviceCenterBase = require("serviceCenterBase")
local searchCenter = class("searchCenter", serviceCenterBase)

function searchCenter:ctor()
    searchCenter.super.ctor(self)
    
end

-- 初始化
function searchCenter:init(kid, idx)
    gLog.i("==searchCenter:init begin==", kid, idx)
    searchCenter.super.init(self, kid)

    -- 服务ID
    self.idx = idx
    -- 地图列表
    self.mapList = {}
    -- 寻路器列表
    self.finderList = {}

    -- 创建地图
    local map = {
        {0,1,0,0,0},
        {0,0,0,1,0},
        {0,1,0,1,0},
        {0,0,0,0,0},
    }
    -- local map = {
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    --  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    -- }
    self.mapList[1] = Grid.new(map)
    -- gLog.dump(self.mapList[1], "searchCenter:init mapList[1]", 10)

    -- 创建寻路器
    self.finderList[1] = PathFinder.new(self.mapList[1], "JPS", 0) --ASTAR THETASTAR LAZYTHETASTAR JPS
    -- gLog.dump(self.finderList[1], "searchCenter:init finderList[1]", 10)

    gLog.i("==searchCenter:init end==", kid, idx)
end

-- 寻路
function searchCenter:getPath(mapID, startX, startY, endX, endY)
    gLog.d("searchCenter:getPath", mapID, startX, startY, endX, endY)
    --
    if not mapID or not startX or not startY or not endX or not endY then
        gLog.i("searchCenter:getPath error1", mapID, startX, startY, endX, endY)
        return
    end
    --
    if not self.finderList[mapID] then
        gLog.i("searchCenter:getPath error2", mapID, startX, startY, endX, endY)
        return
    end
    -- 寻路
    local path = self.finderList[mapID]:getPath(startX, startY, endX, endY)
    -- Pretty-printing the results
    if path then
      print(('path found! Length: %.2f'):format(path:getLength()))
        for node, count in path:nodes() do
          print(('Step: %d - x: %d - y: %d'):format(count, node:getX(), node:getY()))
        end
    end
    return true
end


return searchCenter