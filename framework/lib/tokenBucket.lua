--[[
    流量控制-令牌桶算法
]]
local skynettimer = require("skynettimer")
local tokenBucket = class("tokenBucket")

-- 构造
function tokenBucket:ctor()
    -- 最大令牌数, 即最大瞬时流量
    self.maxTokenNum = 2000

    -- 平均令牌数, 即平均流量, 单位每秒
    self.avgTokenNum = 1000

    -- 当前令牌数
    self.curTokenNum = 0

    -- 计时器
    self.timer = skynettimer.new()
    -- 计时器是否已启动
    self.isStart = false
    self.tid = nil
end

-- 设置最大令牌数
function tokenBucket:setMaxTokenNum(maxTokenNum)
    self.maxTokenNum = maxTokenNum
end

-- 设置平均令牌数
function tokenBucket:setAvgTokenNum(avgTokenNum)
    self.avgTokenNum = avgTokenNum
end

-- 获取令牌
function tokenBucket:getTokens(tokenNum)
    if tokenNum < self.curTokenNum then
        return false
    end
    self.curTokenNum = self.curTokenNum - tokenNum
    return true
end

-- 开始计时器
function tokenBucket:start()
    if self.isStart then
        return
    end
    self.isStart = true
    self.timer:start()
    -- 增加令牌
    self:addTokens(self.avgTokenNum/10)
end

-- 停止计时器
function tokenBucket:stop()
    if self.isStart then
        self.isStart = false
        self.timer:delete(self.tid)
        self.tid = nil
        self.timer:stop()
    end
end

-- 增加令牌
function tokenBucket:addTokens(tokenNum)
    self.curTokenNum = self.curTokenNum + tokenNum
    if self.curTokenNum > self.maxTokenNum then
        self.curTokenNum = self.maxTokenNum
    end
    -- 定时增加令牌
    local _tick = function()
        -- gLog.d("_tick=", self.curTokenNum)
        -- 增加令牌
        self:addTokens(self.avgTokenNum/10)
    end
    -- self.timer:delete(self.tid)
    self.tid = self.timer:add(10, _tick) --100毫秒
end

return tokenBucket