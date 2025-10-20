--[[
    寻路服务中心
]]
local skynet = require("skynet")
local serviceCenterBase = require("serviceCenterBase")
local searchCenter = class("searchCenter", serviceCenterBase)

function searchCenter:ctor()
    searchCenter.super.ctor(self)
end

-- 初始化
function searchCenter:init(serverid, idx)
    gLog.i("==searchCenter:init begin==", serverid, idx)
    -- 服务器ID
    self.serverid = tonumber(serverid)
    -- 索引
    self.idx = idx

    -- 创建地图
    --self.chunckMap = require ("core.grid").new(require("bitmap/chunckmap"))
    --gLog.d("searchCenter:init chunckMap size=", self.chunckMap:getWidth(), self.chunckMap:getHeight())
    --self.posMap = require ("core.grid").new(require("bitmap/posmap"))
    --gLog.d("searchCenter:init posMap size=", self.posMap:getWidth(), self.posMap:getHeight())

    -- 创建寻路器
    --self.chunckFinder = require ("core.pathfinder").new(self.chunckMap, "THETASTAR", 0)
    --self.posFinder = require ("core.pathfinder").new(self.posMap, "THETASTAR", 0)

    local curDir = require("lfs").currentdir()
    self.cppFinder = require("luaMapSearch").new()
    local initOk = self.cppFinder:init(1, 1197, curDir.."/server/map/search/bitmap/posmap.lua", curDir.."/server/map/search/bitmap/EditMapRailwayServer.lua", 133, curDir.."/server/map/search/bitmap/chunckmap.lua", curDir.."/server/map/search/bitmap/zoneconnect.lua")
    if not initOk then
        gLog.e("searchCenter:init cppFinder init error")
    end

    gLog.i("==searchCenter:init end==", serverid, idx)
    return true
end

-- 寻路
function searchCenter:getPath(startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
    gLog.i("searchCenter:getPath", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
    -- 参数检查
    if not startX or not startY or not endX or not endY then
        gLog.e("searchCenter:getPath error1", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
        return false, global_code.error_param
    end
    --
    if startX == endX and startY == endY then
        return true, {path = {{x = startX, y = startY, railway = false}, {x = endX, y = endY, railway = false}}}
    end
    --c++寻路
    if not self.cppFinder then
        return false, global_code.not_servre
    end
    local ret = self.cppFinder:findPath(startX, startY, endX, endY, aid or 0, speed, railwayTime, isReturn and 1 or 0)
    if not ret or not next(ret) then
        gLog.w("searchCenter:getPath error, startX=", startX, "startY=", startY, "endX=", endX, "endY=", endY, "aid=", aid, speed, railwayTime, isReturn)
        if isReturn then --回城寻路失败, 强制寻路成功
            return true, {path = {{x = startX, y = startY, railway = false}, {x = endX, y = endY, railway = false}}}
        else
            return false, global_code.error_find_path
        end
    end
    local path = {}
    for i=1,#ret,3 do
        table.insert(path, {x = ret[i], y = ret[i+1], railway = ret[i+2]})
    end
    return true, {path = path}
end

-- 寻路
function searchCenter:bgetPath(startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
    gLog.i("searchCenter:bgetPath", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
    -- 参数检查
    if not startX or not startY or not endX or not endY then
        gLog.e("searchCenter:bgetPath error1", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
        return false
    end
    --
    if startX == endX and startY == endY then
        return true
    end
    --c++寻路
    if not self.cppFinder then
        return false
    end
    local ret = self.cppFinder:bfindPath(startX, startY, endX, endY, aid or 0, speed, railwayTime, isReturn and 1 or 0)
    if ret then
        return true
    end
    return false
end

-- 更新联盟-铁路关联
function searchCenter:updateRailwayMap(x, y, aid)
    if x and y then
        gLog.i("searchCenter:updateRailwayMap", x, y, aid)
        self.cppFinder:setRailwayAid(x, y, aid)
    end
end

-- 更新联盟-关卡码头关联
function searchCenter:updateCheckMap(x, y, aid)
    if x and y then
        gLog.i("searchCenter:updateCheckMap", x, y, aid)
        self.cppFinder:setCheckAid(x, y, aid)
    end
end

return searchCenter