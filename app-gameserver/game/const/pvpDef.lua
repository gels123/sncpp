--[[
    pvp相关定义
--]]

-- 释放pvp房间的时间
gPvpFreeTime = 2*60
-- tcp心跳超时时间
gPvpHeartbeat = 35

-- pvp相关计时器类型
gPvpTimerType = {
    status = "status", --房间状态计时器
    heartbeat = "heartbeat", --玩家超时计时器
}

-- DEBUG模式特殊配置
if dbconf.DEBUG then
    gPvpFreeTime = 1*60
end