--[[
	登录模块
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local agentCenter = require("agentCenter"):shareInstance()
local baseCtrl = require("baseCtrl")
local loginCtrl = class("loginCtrl", baseCtrl)

-- 初始化
function loginCtrl:init()
    if self.bInit then
        return
    end
    -- 设置已初始化
    self.bInit = true
    -- 是否关闭心跳
    self.close = false
end

-- 玩家checkin
function loginCtrl:checkin()
    -- checkin时已在线, 需开启心跳, 否则可能数据无法释放
    local player = agentCenter:getPlayer()
    local time = svrFunc.systemTime() + 2*gHeartbeatTime
    agentCenter.timerMgr:updateTimer(player:getUid(), gAgentTimerType.heartbeat, time)
end

-- 请求心跳
function loginCtrl:reqHeartbeat()
    if not self.close then
        local player = agentCenter:getPlayer()
        local time = svrFunc.systemTime() + gHeartbeatTime
        agentCenter.timerMgr:updateTimer(player:getUid(), gAgentTimerType.heartbeat, time)
    end
end

-- 请求更改心跳开关
function loginCtrl:reqHeartbeatSwitch(close)
    gLog.d("loginCtrl:reqHeartbeatSwitch close=", close, "fixTest=", self:fixTest())
    if close then
        self.close = true
        local player = agentCenter:getPlayer()
        agentCenter.timerMgr:updateTimer(player:getUid(), gAgentTimerType.heartbeat, 0)
    else
        self.close = false
        loginCtrl:reqHeartbeat()
    end
end

-- 玩家暂离
function loginCtrl:afk()
    if not self.close then
        self.heartbeat = 0
        local player = agentCenter:getPlayer()
        gLog.i("loginCtrl:afk=", player:getUid())
        agentCenter.timerMgr:updateTimer(player:getUid(), gAgentTimerType.heartbeat, self.heartbeat)
    end
end

function loginCtrl:fixTest()
    return "v-0"
end

return loginCtrl
