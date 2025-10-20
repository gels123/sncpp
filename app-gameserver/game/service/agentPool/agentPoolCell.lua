--[[
    玩家代理服务池
--]]
local skynet = require("skynet")
local skynetQueue = require("skynet.queue")
local svrFunc = require("svrFunc")
local svrAddrMgr = require("svrAddrMgr")
local playerDataLib = require("playerDataLib")
local agentPoolCenter = require("agentPoolCenter"):shareInstance()
local agentPoolCell = class("agentPoolCell")

-- 状态
local eStatus =
{
	init = 1,	-- 初始状态
	work = 2,	-- 工作状态
	free = 3,	-- 释放状态
}

-- 构造
function agentPoolCell:ctor()
	-- 玩家ID
	self.uid = nil
	-- 玩家subid
	self.subid = nil
	-- 玩家kid
	self.kid = nil
	-- 是否在线
	self.online = false
	-- agent地址
	self.agent = nil
	-- 状态
	self.status = eStatus.init
	-- 登录时间
	self.checkinTime = 0
	-- 离线时间
	self.afkTime = 0
	-- 释放时间
	self.freeTime = 0
	-- 网关
	self.gate = nil
	-- 用来区分包
	self.channelId = "googleplay"
	-- 串行队列
	self.sq = skynetQueue()
end

-- 获取玩家ID
function agentPoolCell:getUid()
	return self.uid
end

-- 获取玩家subid
function agentPoolCell:getSubid()
	return self.subid
end

-- 获取玩家kid
function agentPoolCell:getKid()
	return self.kid
end

-- 是否在线
function agentPoolCell:getOnline()
	return self.online
end

-- 获取agent
function agentPoolCell:getAgent()
	return self.agent
end

-- 获取gate
function agentPoolCell:getGate()
	return self.gate or svrAddrMgr.getSvr(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
end

-- 是否login成功并处于工作状态
function agentPoolCell:isWork()
	return self.status == eStatus.work
end

-- 登录
function agentPoolCell:login(uid, subid, kid, isNew, version, plateform, model, addr)
	local time = skynet.time()
	return self.sq(function()
		gLog.i("agentPoolCell:login begin=", uid, subid, kid, isNew, version, plateform, model, addr)
		-- 检查是否停服中
		if agentPoolCenter.stoping then
			gLog.w("agentPoolCell:login error0", uid, subid, kid)
			return false
		end
		-- 状态检查
		if self.status ~= eStatus.init then
			gLog.e("agentPoolCell:login error1", uid, subid, kid)
			return false
		end
		-- 赋值
		self.uid = uid
		self.subid = subid
		self.kid = kid
		-- 创建一个新的agent服务
		if self.agent then
			gLog.e("agentPoolCell:login error2", uid, subid, kid)
			return false
		end
		self.agent = skynet.newservice("agent", kid, uid)
		-- 判断是否有热更, 有则先执行热更
		self:hotFix()
		-- 调用agent服务, 玩家登录
		local ok = skynet.call(self.agent, "lua", "login", uid, subid, kid, isNew, version, plateform, model, addr)
		if ok ~= true then
			gLog.e("agentPoolCell:login error3", uid, subid, kid)
			return false
		end
		-- 设置工作状态
		self.status = eStatus.work
		-- 设置释放时间(系统拉起的agent不走checkin)
		self.freeTime = svrFunc.systemTime() + gAgentFreeTime
		agentPoolCenter.timerMgr:updateTimer(self.uid, gAgentPoolTimerType.free, self.freeTime)
		--
		gLog.i("agentPoolCell:login end=", uid, subid, kid, "time=", skynet.time()-time)
		return true
	end)
end

-- 登记连接
function agentPoolCell:checkin(gate, uid, subid, kid, version, plateform, model, addr)
	return self.sq(function()
		gLog.i("agentPoolCell:checkin begin=", gate, uid, subid, kid, version, plateform, model, addr)
		if self.gate and self.uid and self.subid and (self.uid ~= uid or self.kid ~= kid) then
			gLog.e("agentPoolCell:checkin error", gate, uid, subid, kid, self.subid)
			-- 玩家登出(销毁agent)
			if self.agent then
				skynet.send(self.agent, "lua", "logout", "checkin")
			end
			-- 删除网关数据
			skynet.send(self.gate, "lua", "logout", self.uid, self.subid, 4)
			self.gate = nil
			self.subid = nil
			self.agent = nil
			self.online = nil
			-- 设置初始状态
			self.status = eStatus.init
			-- 中断执行
			error(string.format("agentPoolCell:checkin error! uid=%s kid=%s subid=%s", uid, kid, subid))
		end
		-- 检查是否工作状态(是否登陆成功)
		assert(self.status == eStatus.work)
		-- 赋值
		self.gate = gate
		self.uid = uid
		self.subid = subid
		self.kid = kid
		-- 调用agent服务, 玩家checkin
		local ok, isInit = skynet.call(self.agent, "lua", "checkin", subid, version, plateform, model, addr)
		-- 设置登陆时间
		self.checkinTime = svrFunc.systemTime()
		-- 设置玩家在线
		self.online = true
		-- 离线时间
		self.afkTime = 0
		-- 设置释放时间
		self.freeTime = 0
		agentPoolCenter.timerMgr:updateTimer(self.uid, gAgentPoolTimerType.free, self.freeTime)
		--
		gLog.i("agentPoolCell:checkin end=", gate, uid, subid, kid, version, plateform, model, addr, isInit)
		return self.agent, isInit
	end)
end

-- 暂离(gate调用(flag~=4) 或 agent调用(flag==4))
function agentPoolCell:afk(flag)
	return self.sq(function()
		if self.online == nil then -- 已afk
			gLog.w("agentPoolCell:afk ignore=", self.uid, self.subid, self.kid, "flag=", flag)
			return true
		end
		gLog.i("agentPoolCell:afk begin=", self.uid, self.subid, self.kid, "flag=", flag)
		-- 记录离线时间
		self.afkTime = svrFunc.systemTime()
		-- 设置玩家离线
		self.online = nil
		-- 设置释放时间
		self.freeTime = self.afkTime + gAgentFreeTime
		agentPoolCenter.timerMgr:updateTimer(self.uid, gAgentPoolTimerType.free, self.freeTime)
		-- 通知服务离线
		skynet.call(self.agent, "lua", "afk", flag)
	  	-- 调用网关暂离
		if self.gate and self.subid then
			if flag == 4 then
				gLog.i("agentPoolCell:afk send gate afk", self.uid, self.subid, flag)
				skynet.send(self.gate, "lua", "afk", self.uid, self.subid, 4)
			end
		else
			gLog.i("agentPoolCell:afk not send gate afk", self.uid, self.subid)
		end
		--
		gLog.i("agentPoolCell:afk end=", self.uid, self.subid, self.kid, "flag=", flag)
		return true
	end)
end

-- 登出(销毁agent,由gate服调用)
function agentPoolCell:logout(tag)
	-- 设置释放状态
	self.status = eStatus.free
	return self.sq(function()
		gLog.i("agentPoolCell:logout begin==", self.uid, self.subid, self.kid, self.status, "tag=", tag)
		-- 玩家登出(销毁agent)
		if self.agent then
			skynet.send(self.agent, "lua", "logout", tag)
			self.agent = nil
		end
		-- 登出网关
		if self.gate and self.subid then
			-- 调用网关登出
			--gLog.i("agentPoolCell:logout send gate logout", self.uid, self.subid)
			--skynet.send(self.gate, "lua", "logout", self.uid, self.subid, 4)
			-- 删除网关数据
			self.gate = nil
			self.subid = nil
			self.online = nil
		end
		-- 设置初始状态
		self.status = eStatus.init
		-- 邮件登出
		require("mailLib"):afk(self.kid, self.uid)
		-- 通知数据中心玩家彻底离线(数据落地)
		playerDataLib:logout(self.kid, self.uid)
		gLog.i("agentPoolCell:logout end==", self.uid, self.subid, self.kid, self.status, "tag=", tag)
		return true
	end)
end

-- 释放
function agentPoolCell:free()
	gLog.i("agentPoolCell:free", self.uid, self.subid, self.kid)
	--
	self.sq(function()
		if self.agent then
			skynet.send(self.agent, "lua", "free")
		end
		-- 设置初始状态
		self.status = eStatus.init
		-- 通知数据中心玩家彻底离线(数据落地)
		playerDataLib:logout(self.kid, self.uid)
	end)
end

-- 安全释放
function agentPoolCell:safeFree()
	return self.sq(function()
		local stoping = agentPoolCenter.stoping
		if self.online and not stoping then
			gLog.w("agentPoolCell:safeFree ignore1", self.uid, self.subid, self.kid, self.online, stoping)
			return false
		end
		if not self.agent then
			gLog.w("agentPoolCell:safeFree ignore2", self.uid, self.subid, self.kid, self.online, stoping)
			-- 移除Agent
			agentPoolCenter.agentPoolMgr:removeAgent(self.uid)
			-- 通知数据中心玩家彻底离线(数据落地)
			playerDataLib:logout(self.kid, self.uid)
			return true
		end
		local _, ok = pcall(skynet.call, self.agent, "lua", "safeFree")
		if ok == false then
			gLog.w("agentPoolCell:safeFree ignore3", self.uid, self.subid, self.kid)
			self.freeTime = svrFunc.systemTime() + gAgentFreeTime
			agentPoolCenter.timerMgr:updateTimer(self.uid, gAgentPoolTimerType.free, self.freeTime)
			return false
		else -- ok=true/异常
			gLog.i("agentPoolCell:safeFree success uid=", self.uid, "ok=", ok)
			self.agent = nil
			-- 登出网关
			if self.gate and self.subid then
				--gLog.d("agentPoolCell:safeFree send gate logout", self.uid, self.subid, self.kid)
				skynet.call(self.gate, "lua", "logout", self.uid, self.subid, 4)
				-- 删除网关数据
				self.gate = nil
				self.subid = nil
			end
			-- 设置初始状态
			self.status = eStatus.init
			-- 移除Agent
			agentPoolCenter.agentPoolMgr:removeAgent(self.uid)
			-- 通知数据中心玩家彻底离线(数据落地)
			playerDataLib:logout(self.kid, self.uid)
			return true
		end
	end)
end

-- call调用玩家agent
function agentPoolCell:call(...)
	if self.status == eStatus.work and not agentPoolCenter.stoping then --工作状态, 不排队调用
		if self.agent then
			return skynet.call(self.agent, "lua", ...)
		else
			gLog.e("agentPoolCell:call error: not found agent!", self.uid, self.status, ...)
		end
	else --非工作状态, 排队调用
		gLog.i("agentPoolCell:call in line", ...)
		if not self.agent then
			-- 若无agent则login拉起agent
			self:login(self.uid, 0, self.kid)
		end
		return self.sq(function(...)
			if self.agent then
				return skynet.call(self.agent, "lua", ...)
			else
				gLog.w("agentPoolCell:call fail: not found agent!", self.uid, self.status, ...)
			end
		end, ...)
	end
end

-- send调用玩家agent
function agentPoolCell:send(...)
	if self.status == eStatus.work and not agentPoolCenter.stoping then --工作状态, 直接调用
		if self.agent then
			skynet.send(self.agent, "lua", ...)
		else
			gLog.e("agentPoolCell:send error: not found agent!", self.uid, self.status, ...)
		end
	else --非工作状态, 排队调用
		gLog.i("agentPoolCell:send in line", ...)
		if not self.agent then
			-- 若无agent则login拉起agent
			self:login(self.uid, 0, self.kid)
		end
		self.sq(function(...)
			if self.agent then
				skynet.send(self.agent, "lua", ...)
			else
				gLog.w("agentPoolCell:send fail: not found agent!", self.uid, self.status, ...)
			end
		end, ...)
	end
end

-- 执行热更
function agentPoolCell:hotFix()
	local hotFixes = agentPoolCenter.agentPoolMgr.hotFixes
	if hotFixes and self.agent then
		gLog.i("agentPoolCell:hotFix", self.uid)
		xpcall(function()
			skynet.call(self.agent, "lua", "hotFix", hotFixes)
		end, svrFunc.exception)
	end
end

return agentPoolCell
