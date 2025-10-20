--[[
    玩家代理池服务中心
--]]
local skynet = require("skynet")
local mc = require("multicast")
local svrFunc = require("svrFunc")
local serviceCenterBase = require("serviceCenterBase2")
local agentPoolCenter = class("agentPoolCenter", serviceCenterBase)

-- 构造
function agentPoolCenter:ctor()
    agentPoolCenter.super.ctor(self)
end

-- 初始化
function agentPoolCenter:init(kid)
    gLog.i("==agentPoolCenter:init begin==", kid)
    agentPoolCenter.super.init(self, kid)

    -- 迁服锁
    self.lock = {}
    -- 创建频道
    self.poolChannel = mc.new()
    -- 玩家代理池管理
    self.agentPoolMgr = require("agentPoolMgr").new()
    -- 计时器管理器
    self.timerMgr = require("timerMgr").new(handler(self.agentPoolMgr, self.agentPoolMgr.timerCallback), self.myTimer)

    gLog.i("==agentPoolCenter:init end==", kid)
end

-- 获取频道
function agentPoolCenter:getPollChannel()
    return self.poolChannel
end

-- 登陆(登陆服登陆=>网关服登陆=>玩家代理池登陆=>拉起玩家agent服务=>登陆成功)
function agentPoolCenter:login(gate, uid, subid, kid, isNew, version, plateform, model, addr)
    gLog.i("==agentPoolCenter:login begin==", gate, uid, subid, kid, isNew, version, plateform, model, addr)
    local f = function()
        local poolCell = self.agentPoolMgr:startAgent(uid, subid, kid, isNew, version, plateform, model, addr)
        if poolCell then
            local agent, isInit = poolCell:checkin(gate, uid, subid, kid, version, plateform, model, addr)
            gLog.i("==agentPoolCenter:login end==", gate, uid, subid, kid, isInit)
            return agent, isInit
        else
            gLog.e("agentPoolCenter:login fail", uid, subid, kid)
        end
    end
    -- 检查迁服锁, 迁服成功后kid变更, startAgent不会再拉起agent
    if self.lock[uid] then
        return self.lock[uid](f)
    else
        return f()
    end
end

-- 登记连接(仅断线重连gate调用)
function agentPoolCenter:checkin(gate, uid, subid, kid, isNew, version, plateform, model, addr)
    gLog.i("==agentPoolCenter:checkin begin==", gate, uid, subid, kid, isNew, version, plateform, model, addr)
    local poolCell = self.agentPoolMgr:startAgent(uid, subid, kid, isNew, version, plateform, model, addr)
    if poolCell then
        local agent, isInit = poolCell:checkin(gate, uid, subid, kid, version, plateform, model, addr)
        gLog.i("==agentPoolCenter:checkin end==", gate, uid, subid, kid, isInit)
        return agent, isInit
    else
        gLog.e("agentPoolCenter:checkin fail", uid, subid, kid)
    end
end

-- 暂离(gate或agent调用)
function agentPoolCenter:afk(uid, subid, flag)
    gLog.i("==agentPoolCenter:afk begin==", uid, subid, flag)
    local poolCell = self.agentPoolMgr:queryAgent(uid)
    if poolCell then
        poolCell:afk(flag)
        gLog.i("==agentPoolCenter:afk end==", uid, subid)
    else
        gLog.w("agentPoolCenter:afk fail", uid, subid)
    end
end

-- 登出(销毁agent,由gate服调用)
function agentPoolCenter:logout(uid, subid, tag)
    gLog.i("==agentPoolCenter:logout begin==", uid, subid, tag)
    local poolCell = self.agentPoolMgr:queryAgent(uid)
    if poolCell then
        self.agentPoolMgr:removeAgent(uid)
        poolCell:logout(tag)
        gLog.i("==agentPoolCenter:logout end==", uid, subid, tag)
    else
        gLog.w("agentPoolCenter:logout fail", uid, subid, tag)
    end
end

-- call玩家代理(若离线则拉起)
function agentPoolCenter:callAgent(uid, ...)
    gLog.i("agentPoolCenter:callAgent", uid, ...)
    local poolCell = self.agentPoolMgr:startAgent(uid, 0, self.kid)
    if poolCell then
        return poolCell:call(...)
    end
end

-- send玩家代理(若离线则拉起)
function agentPoolCenter:sendAgent(uid, ...)
    gLog.i("agentPoolCenter:sendAgent", uid, ...)
    local poolCell = self.agentPoolMgr:startAgent(uid, 0, self.kid)
    if poolCell then
        poolCell:send(...)
    end
end

-- call在线的玩家代理
function agentPoolCenter:callOnlineAgent(uid, ...)
    gLog.i("agentPoolCenter:callOnlineAgent", uid, ...)
    local poolCell = self.agentPoolMgr:queryAgent(uid)
    if poolCell and poolCell:getOnline() then
        return poolCell:call(...)
    end
end

-- send在线的玩家代理
function agentPoolCenter:sendOnlineAgent(uid, ...)
    gLog.i("agentPoolCenter:sendOnlineAgent", uid, ...)
    local poolCell = self.agentPoolMgr:queryAgent(uid)
    if poolCell and poolCell:getOnline() then
        poolCell:send(...)
    end
end

-- call所有在线的玩家代理
function agentPoolCenter:callAllOnlineAgents(...)
    gLog.i("agentPoolCenter:callAllOnlineAgents", ...)
    local ret = {}
    local uids = self.agentPoolMgr:getOnlinePlayers()
    for _,uid in pairs(uids) do
        local poolCell = self.agentPoolMgr:queryAgent(uid)
        if poolCell and poolCell:getOnline() then
            ret[uid] = poolCell:call(...)
        end
    end
    return ret
end

-- send所有在线的玩家代理
function agentPoolCenter:sendAllOnlineAgents(...)
    gLog.i("agentPoolCenter:sendAllOnlineAgents", ...)
    local uids = self.agentPoolMgr:getOnlinePlayers()
    for _,uid in pairs(uids) do
        local poolCell = self.agentPoolMgr:queryAgent(uid)
        if poolCell and poolCell:getOnline() then
            poolCell:send(...)
        end
    end
end

-- 给客户端推送消息
function agentPoolCenter:notifyMsg(uid, cmd, msg)
    if dbconf.DEBUG then
        gLog.d("agentPoolCenter:notifyMsg uid=", uid, cmd, table2string(msg))
    end
    if uid and cmd and msg then
        local poolCell = self.agentPoolMgr:queryAgent(uid)
        if poolCell and poolCell:getOnline() then
            poolCell:send("notifyMsg", cmd, msg)
        else
            gLog.w("agentPoolCenter:notifyMsg failed, uid=", uid, cmd, table2string(msg))
        end
    end
end

-- 批量通知在线玩家
function agentPoolCenter:notifyMsgBatch(uids, cmd, msg, exp)
    if dbconf.DEBUG then
        gLog.d("agentPoolCenter:notifyMsgBatch uids=", table2string(uids), cmd, table2string(msg), exp)
    end
    if uids and cmd and msg then
        --local opt = 0
        for _,uid in ipairs(uids) do
            if uid ~= exp then
                local poolCell = self.agentPoolMgr:queryAgent(uid)
                if poolCell and poolCell:getOnline() then
                    poolCell:send("notifyMsg", cmd, msg)
                end
                --opt = opt + 1
                --if opt%50 == 0 then
                --    skynet.sleep(0)
                --end
            end
        end
    end
end

-- 批量通知所有在线玩家
function agentPoolCenter:notifyMsgAll(cmd, msg)
    if dbconf.DEBUG then
        gLog.d("agentPoolCenter:notifyMsgAll", cmd, table2string(msg))
    end
    if cmd and msg then
        local opt = 0
        local agentPool = self.agentPoolMgr:getAgentPool()
        for uid,poolCell in pairs(agentPool) do
            if poolCell and poolCell:getOnline() then
                poolCell:send("notifyMsg", cmd, msg)
            end
            opt = opt + 1
            if opt%50 == 0 then
                skynet.sleep(0)
            end
        end
    end
end

-- 获取在线人数
function agentPoolCenter:getOnlinePlayersNum()
    return self.agentPoolMgr:getOnlinePlayersNum()
end

-- 获取所有玩家UID
function agentPoolCenter:getAllPlayers()
    return self.agentPoolMgr:getAllPlayers()
end

-- 获取在线玩家UID、离线玩家UID
function agentPoolCenter:getOnlinePlayers(uids)
    if uids then
        local onlineUids, offlineUids = {}, {}
        for i, uid in ipairs(uids) do
            local poolCell = self.agentPoolMgr:queryAgent(uid)
            if poolCell and poolCell:getOnline() then
                table.insert(onlineUids, uid)
            else
                table.insert(offlineUids, uid)
            end
        end
        return onlineUids, offlineUids
    else
        return self.agentPoolMgr:getOnlinePlayers()
    end
end

-- 迁出本服入口
function agentPoolCenter:migrateOut(uid, newKid)
    gLog.i("agentPoolCenter:migrateOut begin=", uid, newKid)
    local f = function(uid)
        -- 设置迁服锁
        if not self.lock[uid] then
            self.lock[uid] = self:getSq(uid)
        end
        -- 串行执行
        self.lock[uid](function()
            -- 踢出, 同时玩家数据落地
            local poolCell = self.agentPoolMgr:queryAgent(uid)
            if poolCell then
                gLog.i("agentPoolCenter:migrateOut do=", poolCell:getUid(), poolCell:getSubid())
                poolCell:logout(3)
                if poolCell:getGate() then
                    xpcall(function()
                        skynet.call(poolCell:getGate(), "lua", "logout", poolCell:getUid(), poolCell:getSubid(), 3)
                    end, svrFunc.exception)
                end
            end
            -- 邮件登出
            require("mailLib"):logout(self.kid, uid)
            -- 再次通知数据中心, 玩家数据落地
            xpcall(function()
                local playerDataLib = require("playerDataLib")
                playerDataLib:logout(self.kid, uid, newKid)
            end, svrFunc.exception)
        end)
        -- 取消迁服锁
        self.lock[uid] = nil
    end
    if uid then -- 玩家迁服
        f(uid)
    end
    gLog.i("agentPoolCenter:migrateOut end=", uid, newKid)
end

-- 迁入本服(login服调用)
function agentPoolCenter:migrateIn(uid, newKid)
    gLog.i("agentPoolCenter:migrateIn begin=", uid, newKid)
    self:migrateOut(uid, self.kid)
    gLog.i("agentPoolCenter:migrateIn end=", uid, newKid)
end

-- 检查迁服锁
function agentPoolCenter:checkLock(uid)
    if self.lock[uid] then
        self.lock[uid](function() end)
        return true
    end
end

-- 发送邮件
function agentPoolCenter:sendMail(uid, ...)
    local sq = self:getSq(uid)
    sq(function(...)
        local kid = require("playerDataLib"):getKidOfUid(self.kid, uid)
        gLog.i("agentPoolCenter:sendMail=", uid, kid, ...)
        if kid and kid > 0 then
            local ok = require("mailLib"):call(kid, uid, "sendMail", ...)
            gLog.i("agentPoolCenter:sendMail ok=", uid, kid, ok)
        else
            gLog.e("agentPoolCenter:sendMail error=", uid, kid, ...)
        end
    end, ...)
end

-- 停服维护
function agentPoolCenter:serverMaintenance()
    local ret = self.agentPoolMgr:getOnlinePlayers()
    for i, uid in ipairs(ret) do
        local poolCell = self.agentPoolMgr:queryAgent(uid)
        if poolCell and poolCell:getOnline() then
            -- 推送服务器维护
            poolCell:send("notifyMsg", "notifyMaintain", {status = gServerStatus.MAINTENANCE,})
            -- 暂离
            skynet.fork(function()
                poolCell:afk(4)
            end)
        end
    end
end

-- 停止服务
function agentPoolCenter:stop()
    gLog.i("agentPoolCenter:stop begin=", self.kid)
    -- 标记停服中
    if self.stoping then
        return
    end
    self.stoping = true
    -- 等待所有任务都处理完, 再标记已停服
    skynet.fork(function()
        if not dbconf.DEBUG then
            skynet.sleep(500)
        end
        -- 停止服务
        self.agentPoolMgr:stop()
        while(true) do
            local total = self.agentPoolMgr:getAgentTotalNum()
            if total <= 0 then
                -- 检查消息队列和协程
                local mqlen = skynet.mqlen() or 0
                local task = {}
                local taskLen = skynet.task(task) or 0
                if mqlen > 0 or taskLen > 0 then
                    gLog.i("agentCenter:stop waiting mq and task, mqlen=", mqlen, "taskLen=", taskLen, "task=", table2string(task))
                else
                    --gLog.i("agentCenter:stop waiting mq and task, mqlen=", mqlen, "taskLen=", taskLen, "task=", table2string(task))
                    break
                end
            else
                gLog.i("agentCenter:stop waiting total=", total)
            end
            skynet.sleep(200)
        end
        -- 标记已停服
        self.stoped = true
        if self.myTimer then
            self.myTimer:pause()
        end
    end)
    gLog.i("agentPoolCenter:stop end=", self.kid)
end

-- 执行玩家服热更
function agentPoolCenter:hotFix(script)
    gLog.i("agentPoolCenter:hotFix enter script=", script)
    self.agentPoolMgr:hotFix(script)
    gLog.i("agentPoolCenter:hotFix end script=", script)
    return true
end

return agentPoolCenter
