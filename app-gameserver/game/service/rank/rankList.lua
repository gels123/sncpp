--[[
    排行榜
]]
local skynet = require("skynet")
local rankConf = require "rankConf"
local rankCenter = require("rankCenter"):shareInstance()
local rankList = class("rankList")

-- 构造
function rankList:ctor(rankId)
    assert(rankId and rankConf.rankType2[rankId])
    self.key = string.format(rankConf.rankKey, rankCenter.kid, rankId)
    if rankConf.rankGlobal[rankId] then
        -- 全服排行榜
        self.redisLib = require("publicRedisLib")
    else
        -- 本地排行榜
        self.redisLib = require("redisLib")
    end
end

-- 增加到排行榜
function rankList:addRank(id, score)
    gLog.d("rankList:addRank:", self.key, id, score)
    if id and score then
        self.redisLib.zAdd(self.key, score, tostring(id))
    end
end

-- 获取排名
function rankList:getRank(id)
    if not id then
        return 0
    end
    local rank = self.redisLib.zRevRank(self.key, tostring(id))
    if rank then
        return rank + 1
    end
    return 0
end

-- 获取排行
-- @startRank、endRank   开始排名、结束排名(第1-100名传0-99)
-- @withScore            是否获取积分
function rankList:getRange(startRank, endRank, withScore, isFloor)
    local ret = {}
    local range = self.redisLib.zRevRange(self.key, startRank, endRank, withScore)
    if range then
        if withScore then
            for k = 1, #range, 2 do
                if range[k] and range[k+1] then
                    table.insert(ret, {rankidx = math.floor(tonumber((k+1)/2)), id = tonumber(range[k]), score = isFloor and math.floor(tonumber(range[k+1])) or tonumber(range[k+1])})
                end
            end
        else
            for k,v in ipairs(range) do
                table.insert(ret, {rankidx = tonumber(k), id = tonumber(v)})
            end
        end
    end
    -- gLog.dump(ret, "rankList:getRange ret=")
    return ret
end

-- 获取积分
function rankList:getScore(id)
    if not id then
        return 0
    end
    local score = self.redisLib.zScore(self.key, tostring(id)) or 0
    return math.floor(tonumber(score))
end

-- 清除排行榜
function rankList:clear()
    gLog.i("rankList:clear", self.key)
    self.redisLib.delete(self.key)
end

-- 清除排名
function rankList:clearId(id)
    gLog.i("rankList:clearId", id)
    if id then
        self.redisLib.zRem(self.key, tostring(id))
    end
end

return rankList

