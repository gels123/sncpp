--[[
    排行榜服务中心
]]
local skynet = require "skynet"
local svrFunc = require "svrFunc"
local serviceCenterBase = require("serviceCenterBase2")
local rankCenter = class("rankCenter", serviceCenterBase)

-- 构造
function rankCenter:ctor()
    rankCenter.super.ctor(self)

end

-- 初始化
function rankCenter:init(kid, idx)
    gLog.i("rankCenter:init begin=", kid, idx)
    rankCenter.super.init(self, kid)

    -- 王国ID
    self.kid = tonumber(kid)
    -- 索引
    self.idx = idx
    -- 排行榜
    self.rankLists = {}

    gLog.i("rankCenter:init end=", kid, idx)
    return true
end

function rankCenter:getRankList(rankId)
    rankId = tonumber(rankId)
    if not self.rankLists[rankId] then
        self.rankLists[rankId] = require("rankList").new(rankId)
    end
    return self.rankLists[rankId]
end

-- 增加到排行榜
function rankCenter:addRank(rankId, id, score)
    local rankList = self:getRankList(rankId)
    rankList:addRank(id, score)
end

-- 获取排名
function rankCenter:getRank(rankId, id)
    local rankList = self:getRankList(rankId)
    return rankList:getRank(id)
end

-- 获取排行
function rankCenter:getRange(rankId, startRank, endRank, withScore, isFloor)
    local rankList = self:getRankList(rankId)
    return rankList:getRange(startRank, endRank, withScore, isFloor)
end

-- 获取积分
function rankCenter:getScore(rankId, id)
    local rankList = self:getRankList(rankId)
    return rankList:getScore(id)
end

-- 清除排行榜
function rankCenter:clear(rankId)
    local rankList = self:getRankList(rankId)
    rankList:clear()
end

-- 清除排名
function rankCenter:clearId(rankId, id)
    local rankList = self:getRankList(rankId)
    rankList:clearId(id)
end

return rankCenter