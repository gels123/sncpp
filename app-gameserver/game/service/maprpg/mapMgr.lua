--[[
	地图管理器
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local mapCenter = require("mapCenter"):shareInstance()
local mapMgr = class("mapMgr")

-- 构造
function mapMgr:ctor()
    -- 地图类型--地图类
    self.mapType2Class =
    {
        [mapConf.mapTypes.map] = require("map"),
    }
    -- 地图类型-地图
	self.maps = {}
    -- 地图ID-地图
    self.mapids = {}
end

-- 初始化
function mapMgr:init()
    gLog.i("==mapMgr:init begin==")
    -- 清理地图同屏人数排序
    if mapCenter.idx == 1 then
        local redisLib = require("redisLib")
        for _,tp in pairs(mapConf.mapTypes) do
            redisLib:delete(self:findMapKey(tp))
        end
    end
    gLog.i("==mapMgr:init end==")
end

-- 获取地图类
function mapMgr:getClass(tp)
    return assert(self.mapType2Class[tp])
end

-- 地图查找redis键值
function mapMgr:findMapKey(tp)
    return string.format("game-findmap-%d-%d", mapCenter.kid, tp)
end

-- 获取地图
function mapMgr:getMap(tp, mapid, flag)
    assert(tp and mapid)
    local sq = mapCenter:getSq(tp)
    local map = nil
    sq(function()
        if not self.maps[tp] then
            self.maps[tp] = {}
        end
        if not self.maps[tp][mapid] then
            if not flag then --flag==true, 不新建
                local class = self:getClass(tp)
                self.maps[tp][mapid] = class.new(tp, mapid)
            end
        end
        map = self.maps[tp][mapid]
    end)
    return map
end

-- 释放地图
function mapMgr:delMap(tp, mapid)
    assert(tp and mapid)
    local sq = mapCenter:getSq(tp)
    sq(function()
        local map = self.maps[tp] and self.maps[tp][mapid]
        if map then
            -- 删除倒计时
            for _,v in pairs(mapConf.mapTimers) do
                mapCenter.timerMgr:updateTimer(mapid, v, 0)
            end
            -- 释放地图
            self.maps[tp][mapid] = nil
            if not next(self.maps[tp]) then
                self.maps[tp] = nil
            end
            map = nil
        end
    end)
    -- 释放sq
    mapCenter:delSq(tp)
end


return mapMgr
