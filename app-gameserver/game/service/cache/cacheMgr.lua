--[[
	缓存数据管理
--]]
local skynet = require("skynet")
local svrFunc = require "svrFunc"
local playerDataLib = require "playerDataLib"
local cacheCenter = require("cacheCenter"):shareInstance()
local cacheMgr = class("cacheMgr")

-- 缓存淘汰时间
local cacheTs = dbconf.DEBUG and 60 or 15*60

-- 构造
function cacheMgr:ctor()
    -- 玩家缓存数据
    self.playerCaches = {}
    -- 联盟缓存数据
    self.allianceCaches = {}
end

-- 获取玩家数据缓存
function cacheMgr:getCachePlayer(uid)
    uid = tonumber(uid)
    local sq = cacheCenter:getSq(uid)
    return sq(function()
        if not self.playerCaches[uid] then
            self.playerCaches[uid] = require("cachePlayer").new(uid)
            self.playerCaches[uid]:init()
            cacheCenter.timerMgr:updateTimer(uid, 0, svrFunc.systemTime()+cacheTs)
        end
        return self.playerCaches[uid]
    end)
end

-- 删除玩家数据缓存
function cacheMgr:delCachePlayer(uid, delDb)
    local sq = cacheCenter:getSq(uid)
    sq(function()
        if delDb then -- 删除DB数据
            playerDataLib:sendDelete(cacheCenter.kid, uid, "cacheplayer")
        end
        self.playerCaches[uid] = nil
    end)
end

-- 获取联盟数据缓存
function cacheMgr:getCacheAlliance(aid)
    aid = tonumber(aid)
    local sq = cacheCenter:getSq(aid)
    return sq(function()
        if not self.allianceCaches[aid] then
            self.allianceCaches[aid] = require("cacheAlliance").new(aid)
            self.allianceCaches[aid]:init()
            cacheCenter.timerMgr:updateTimer(aid, 1, svrFunc.systemTime()+cacheTs)
        end
        return self.allianceCaches[aid]
    end)
end

-- 删除联盟数据缓存
function cacheMgr:delCacheAlliance(aid, isDB)
    local sq = cacheCenter:getSq(aid)
    sq(function()
        self.allianceCaches[aid] = nil
        if isDB then -- 删除DB数据
            playerDataLib:sendDelete(cacheCenter.kid, aid, "cachealliance")
        end
    end)
end

return cacheMgr
