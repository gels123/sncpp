--[[
	玩家代理服务中心
--]]
local skynet = require("skynet")
local mc = require("multicast")
local playerDataLib = require "playerDataLib"
local gLog = require("newLog")
local serviceCenterBase = require("serviceCenterBase2")
local agentCenter = class("agentCenter", serviceCenterBase)

-- 构造
function agentCenter:ctor()
	self.super.ctor(self)
end

-- 初始化
function agentCenter:init(kid)
    gLog.i("==agentCenter:init begin==", kid)

	-- 王国ID
	self.kid = kid
    -- 计时器
    self.myTimer = require("scheduler2").new()
    -- 玩家
	self.player = require("player").new()
	-- 计时器管理器
	self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)

	-- 开始服务
	self:start()

    gLog.i("==agentCenter:init end==", kid)
    return true
end

-- 设置玩家fd(玩家连接网关握手成功时调用)
function agentCenter:setFd(fd)
	self.player:setFd(fd)
end

-- 获取玩家
function agentCenter:getPlayer()
	return self.player
end

-- 玩家登陆
function agentCenter:login(uid, subid, kid, isNew, version, plateform, model, addr)
	-- you may use secret to make a encrypted data stream
	gLog.i("==agentCenter:login begin==", uid, subid, kid, isNew, version, plateform, model, addr)
	local ok = self.player:login(uid, subid, kid, isNew, version, plateform, model, addr)
	gLog.i("==agentCenter:login end==", uid, subid, kid)
	return ok
end

-- 玩家后台切入
function agentCenter:checkin(subid, version, plateform, model, addr)
	gLog.i("==agentCenter:checkin begin==", self.player:getUid(), subid, version, plateform, model, addr)
	local ok, isInit = self.player:checkin(subid, version, plateform, model, addr)
	gLog.i("==agentCenter:checkin end==", self.player:getUid(), subid, isInit)
	return ok, isInit
end

-- 玩家暂离/切入后台(仅由agentpool调用)
function agentCenter:afk(flag)
	-- NOTICE: the connection is broken, but the user may back
	gLog.i("==agentCenter:afk begin==", self.player:getUid(), self.player:getSubid(), flag)
	local ok = self.player:afk(flag)
	gLog.i("==agentCenter:afk end==", self.player:getUid(), self.player:getSubid())
	return ok
end

-- 玩家登出(销毁agent)
function agentCenter:logout(tag)
	-- NOTICE: The logout MAY be reentry
	gLog.i("==agentCenter:logout begin==", self.player:getUid(), self.player:getSubid())
	pcall(function()
		self.player:logout(tag)
	end)
	gLog.i("==agentCenter:logout end==", self.player:getUid(), self.player:getSubid())
	-- 销毁
	skynet.exit()
end

-- 释放
function agentCenter:free()
	gLog.i("==agentCenter:free==", self.player:getUid(), self.player:getSubid())
	pcall(function()
		self.player:logout()
	end)
	-- 销毁
	skynet.exit()
end

-- 安全释放
function agentCenter:safeFree()
	gLog.i("==agentCenter:safeFree==", self.player:getUid())
	-- 检查消息队列长度
	local time = svrFunc.skynetTime()
	local mqlen = skynet.mqlen() or 0
	if svrFunc.skynetTime() - time > 1 then
		gLog.i("agentCenter:safeFree timeout1=", self.player:getUid())
	end
	if mqlen > 0 then
		gLog.i("agentCenter:safeFree fail1", self.player:getUid(), mqlen)
		return false
	end
	-- 检查协程
	local ret = dbconf.DEBUG and {} or nil
	local taskLen = skynet.task(ret) or 0
	local sharedataLen = require("sharedataLib").getQueryCount() or 0
	local timerLen = require("scheduler2"):getSchedulerCount() or 0
	if svrFunc.skynetTime() - time > 1 then
		gLog.i("agentCenter:safeFree timeout2=", self.player:getUid())
	end
	gLog.i("agentCenter:safeFree uid=", self.player:getUid(), "taskLen=", taskLen, "sharedataLen=", sharedataLen, "timerLen=", timerLen)
	if taskLen <= sharedataLen + timerLen then
		pcall(function()
			self.player:logout()
		end)
		gLog.i("agentCenter:safeFree success", self.player:getUid())
		-- 销毁
		skynet.fork(function()
			skynet.exit()
		end)
		return true
	else
		gLog.i("agentCenter:safeFree fail2", self.player:getUid(), "cost time=", svrFunc.skynetTime() - time)
		if dbconf.DEBUG then
			gLog.dump(ret, "agentCenter:safeFree task ret=", 10)
		end
		return false
	end
end

-- 释放
function agentCenter:isFree()
	--判断消息队列长度
	local mqlen = skynet.mqlen() or 0
	if mqlen > 0 then
		return false
	end
	--判断协程
	local ret = dbconf.DEBUG and {} or nil
	local taskLen = skynet.task(ret)
	local sharedataLen = require("sharedataLib").getQueryCount()
	local timerLen = require("scheduler2"):getSchedulerCount()
	local sockTaskLen = 0
	gLog.i("agentCenter:isFree taskLen=", taskLen, "sharedataLen=", sharedataLen, "timerLen=", timerLen, "sockTaskLen=", sockTaskLen)
	if taskLen <= sharedataLen + timerLen + sockTaskLen then
		return true
	else
		return false
	end
end

-- 给客户端推送消息
function agentCenter:notifyMsg(cmd, msg)
	if self.player then
		self.player:notifyMsg(cmd, msg)
	else
		gLog.w("agentCenter:notifyMsg failed, uid=", self.player:getUid(), cmd, table2string(msg))
	end
end

-- 获取联盟ID
function agentCenter:getAid()
	return self.player and self.player:getAid()
end

-- call调用指定模块的指定方法
function agentCenter:callModule(module, cmd, ...)
	if not self.player then
		gLog.e("agentCenter:callModule err", module, cmd, ...)
		return
	end
	local ctrl = self.player:getModule(module)
	local f = ctrl[cmd]
	if type(f) == "function" then
		return f(ctrl, ...)
	else
		gLog.e("agentCenter:callModule err", self.player:getUid(), module, cmd, ...)
	end
end

-- send调用指定模块的指定方法
function agentCenter:sendModule(module, cmd, ...)
	if not self.player then
		gLog.e("agentCenter:sendModule err", module, cmd, ...)
		return
	end
	local ctrl = self.player:getModule(module)
	local f = ctrl[cmd]
	if type(f) == "function" then
		f(ctrl, ...)
	else
		gLog.e("agentCenter:sendModule err", self.player:getUid(), module, cmd, ...)
	end
end

-- 热更
function agentCenter:hotFix(hotFixes)
	if self.player then
		self.player:hotFix(hotFixes)
	else
		gLog.e("agentCenter:hotFix err: no player")
	end
end

-- 计时器回调
function agentCenter:timerCallback(data)
	if dbconf.DEBUG then
		gLog.d("agentCenter:timerCallback data=", table2string(data))
	end
	local uid, timerType = data.id, data.timerType
	if self.timerMgr:hasTimer(uid, timerType) then
		local player = self:getPlayer()
		if timerType == gAgentTimerType.heartbeat then
			player:onLinkTimeout()
		elseif timerType == gAgentTimerType.buff then
			local buffCtrl = player:getModule(gModuleDef.buffModule)
			buffCtrl:timerCallback()
		elseif timerType == gAgentTimerType.newDay then
			player:onNewDay()
		else
			gLog.w("agentCenter:timerCallback ignore", uid, timerType)
		end
	end
end

return agentCenter
