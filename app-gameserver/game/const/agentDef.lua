--[[
    agent相关定义
--]]

-- 心跳超时时间
gHeartbeatTime = 45

-- 释放agent时间
gAgentFreeTime = 15*60

-- 玩家agent池计时器类型
gAgentPoolTimerType = {
    free = "free", --释放agent
}

-- 玩家agent计时器类型
gAgentTimerType = {
    heartbeat = "heartbeat", --心跳超时
    buff = "buff",           --buff倒计时
    newDay = "newDay",       --新的一天倒计时
}

-- DEBUG模式特殊配置
if dbconf.DEBUG then
    gAgentFreeTime = 5*60
end