--[[
	游戏玩家上层逻辑
--]]
local skynet = require("skynet")
local socketdriver = require("skynet.socketdriver")
local netpack = require ("skynet.netpack")
local mc = require("skynet.multicast")
local svrAddrMgr = require("svrAddrMgr")
local dbconf = require("dbconf")
local svrFunc = require("svrFunc")
local multiProc = require("multiProc")
local protoLib = require("protoLib")
local clientCmd = require("clientCmd")
local skynetQueue = require("skynet.queue")
local eventCtrl = require("eventCtrl")
local lfs = require("lfs")
local gLog = require("newLog")
local agentCenter = require("agentCenter"):shareInstance()
local player = class("player")

-- 注册客户端指令(遍历module目录require "xxxCmd")
do
	local function loadCmdFiles(path)
		for file in lfs.dir(path) do
			if file ~= "." and file ~= ".." then
				local fullPath = path .. "/" .. file
				local attr = lfs.attributes(fullPath)
				if attr.mode == "directory" then
					loadCmdFiles(fullPath)
				elseif file:match(".*Cmd%.lua$") then
					file = file:gsub("%.lua$", "")
					require(file)
				end
			end
		end
	end
	loadCmdFiles(lfs.currentdir().."/game/service/agent/module")
end

-- 构造
function player:ctor()
	self.kid = nil          -- 王国ID
	self.uid = nil    		-- 玩家ID
	self.subid = nil        -- 玩家subid
	self.aid = 0			-- 联盟ID
	self.version = nil      -- 客户端版本
	self.online = nil   	-- 是否在线
	self.fd = nil           -- 套接字fd
	self.isNew = nil		-- 是否新号

	self.plateform_ = nil   -- 手机平台
	self.plateformVersion_ = nil -- 手机平台版本
	self.deviceId_ = nil    -- 设备id
	self.model = nil        -- 手机型号
	self.clientIp = nil     -- 客户端ip
	self.clientLanguage_ = nil -- 客户端语言

	self.modules = {}		-- 模块

    self.msgNotify = {}   	-- 推送消息队列

    self.checkinTime = nil 	-- checkin时间
    self.afkTime = nil 		-- afk时间

    self.hotFixes = nil 	-- 热更参数
	self.sq = skynetQueue() -- 串行队列
end

-- 获取王国ID
function player:getKid()
	return self.kid
end

-- 获取玩家ID
function player:getUid()
    return self.uid
end

-- 获取玩家subid
function player:getSubid()
    return self.subid
end

-- 获取联盟ID
function player:getAid()
	local lordCtrl = self:getModule(gModuleDef.lordModule)
	return lordCtrl:getAttr("aid") or 0
end

-- 获取客户端版本
function player:getVersion()
	return self.version
end

-- 是否在线
function player:getOnline()
	return self.online
end

-- 获取套接字fd
function player:getFd()
    return self.fd
end

-- 获取手机平台
function player:getPlateform()
    return self.plateform_
end

-- 获取手机平台版本
function player:getPlateformVersion()
    return self.plateformVersion_
end

-- 获取设备id
function player:getDeviceId()
    return self.deviceId_
end

-- 获取手机型号
function player:getModel()
    return self.model
end

-- 获取客户端ip
function player:getClientIp()
    return self.clientIp
end

--获取客户端语言
function player:getClientLanguage()
	return self.clientLanguage_
end

-- 获取模块
function player:getModule(module)
	--gLog.d("player:getModule", self:getUid(), moduleName)
	if not self.modules[module] then
		self.modules[module] = require(module).new(self.uid)
	end
	assert(self.modules[module], "player:getModule error: module not exist!")
	return self.modules[module]
end

-- 玩家登录, 新玩家需要生成相应的数据库记录, 老玩家从数据库中加载数据
function player:login(uid, subid, kid, isNew, version, plateform, model, addr)
	return self.sq(function()
		gLog.i("==player:login begin==", uid, subid, kid, isNew, version, plateform, model, addr)
		--
		self.uid = uid
		self.subid = subid
		self.kid = kid
		self.isNew = isNew
		self.afkTime = nil
		self.msgNotify = {}
		if version then
			self.version = version
		end
		if plateform then
			self.plateform_, self.plateformVersion_, self.deviceId_, self.clientLanguage_ = svrFunc.splitPlateformInfo(plateform)
		end
		if model then
			self.model = model
		end
		if addr then
			self.clientIp = svrFunc.splitAddr(addr)
		end
		-- init模块
		self:initModule()
		-- 执行热更
		self:doHotFix()
		-- 各模块init后再触发条件
		require("conditionMgr").start()
		-- 登录事件
		self:dispatchEvent(gEventDef.Event_UidLogin)
		gLog.i("==player:login end==", uid, subid, kid, isNew, version, plateform, model, addr)
		return true
	end)
end

-- 玩家已连接到网关, 并已通过网关认证
function player:checkin(subid, version, plateform, model, addr)
	return self.sq(function()
		gLog.i("==player:checkin begin==", self.uid, self.subid, self.kid, "subid=", subid)
		--
		self.subid = subid
		if version then
			self.version = version
		end
		if plateform then
			self.plateform_, self.plateformVersion_, self.deviceId_, self.clientLanguage_ = svrFunc.splitPlateformInfo(plateform)
		end
		if model then
			self.model = model
		end
		if addr then
			self.clientIp = svrFunc.splitAddr(addr)
		end
		-- 客户端是否需要重新初始化
		local isInit = not (self.afkTime and self.afkTime > 0 and svrFunc.systemTime() < self.afkTime)
		-- 设置在线
		self.online = true
		-- 设置checkin时间、afk时间
		self.checkinTime = svrFunc.systemTime()
		self.afkTime = 0
		-- checkin模块
		self:checkinModule()
		-- 添加跨天倒计时
		agentCenter.timerMgr:updateTimer(self:getUid(), gAgentTimerType.newDay, svrFunc.getWeehoursUTC()+86400)
		gLog.i("==player:checkin end==", self.uid, self.subid, self.kid, "subid=", subid, isInit)
		return true, isInit
	end)
end

-- 玩家离线, agent服务还在
function player:afk(flag)
	return self.sq(function()
		gLog.i("==player:afk begin==", self.uid, self.subid, self.kid)
		-- 推送登出
		if self.online and flag then
			self:notifyMsg("notifyLogout", {flag = flag,})
		end
		-- 设置套接字fd
		self.fd = nil
		-- 设置离线
		self.online = false
		-- 设置afk时间
		if self.afkTime == 0 then
			self.afkTime = svrFunc.systemTime() + 30
		end
		-- afk模块
		self:afkModule()
		-- 删除跨天倒计时
		agentCenter.timerMgr:updateTimer(self:getUid(), gAgentTimerType.newDay)
		-- 回收内存
		skynet.send(skynet.self(),"debug", "GC")
		gLog.i("==player:afk end==", self.uid, self.subid, self.kid)
		return true
	end)
end

-- 玩家从登录服务器登出
function player:logout(tag)
	return self.sq(function()
		gLog.i("==player:logout begin==", self.uid, self.subid, self.kid, "tag=", tag)
		-- 设置离线
		self.online = false
		-- 设置afk时间
		self.afkTime = nil
		-- logout模块
		self:logoutModule()
		-- 删除跨天倒计时
		agentCenter.timerMgr:updateTimer(self:getUid(), gAgentTimerType.newDay)
		-- 回收内存
		skynet.send(skynet.self(),"debug", "GC")
		gLog.i("==player:logout end==", self.uid, self.subid, self.kid)
		return true
	end)
end

-- init模块
function player:initModule()
	gLog.i("==player:initModule begin", self.uid)
	local time = skynet.time()
	-- 并行执行查库任务(mysql会是性能热点), 需优先初始化的模块放上面
	------- 需要优先初始化的模块 ------->
	local loginCtrl = self:getModule(gModuleDef.loginModule)
	loginCtrl:init()

	------- 无需优先初始化的模块 ------->
	local mp = multiProc.new()
	for k,module in pairs(gModuleDef) do
		if not self.modules[module] then
			mp:fork(function ()
				local ctrl = self:getModule(module)
				ctrl:init()
			end)
		end
	end
	-- 邮件登录
	mp:fork(function()
		require("mailLib"):login(self.kid, self.uid)
	end)
	-- 等待所有任务执行结束
	mp:wait()
	gLog.i("==player:initModule end", self.uid, "time=", skynet.time()-time)
end

-- checkin模块(按需追加)
function player:checkinModule()
	gLog.i("==player:checkinModule begin", self.uid)
	for k,v in pairs(self.modules) do
		if v.checkin then
			v:checkin()
		end
	end
	-- 邮件checkin
	require("mailLib"):checkin(self.kid, self.uid)
	gLog.i("==player:checkinModule end", self.uid)
end

-- afk模块
function player:afkModule()
	gLog.i("==player:afkModule begin", self.uid)
	for k,v in pairs(self.modules) do
		if v.afk then
			v:afk()
		end
	end
	-- 邮件afk
	require("mailLib"):afk(self.kid, self.uid)
	gLog.i("==player:afkModule end", self.uid)
end

-- logout模块
function player:logoutModule()
	gLog.i("==player:logoutModule begin", self.uid)
	for k,v in pairs(self.modules) do
		if v.logout then
			v:logout()
		end
	end
	-- 邮件logout
	require("mailLib"):logout(self.kid, self.uid)
	gLog.i("==player:logoutModule end", self.uid)
end

-- 新的一天
function player:onNewDay()
	gLog.i("player:onNewDay=", self:getUid(), self.online)
	for k,v in pairs(self.modules) do
		if v.onNewDay then
			v:onNewDay()
		end
	end
end

-- 链路超时通知
function player:onLinkTimeout()
	gLog.i("player:onLinkTimeout", self:getUid(), self:getSubid())
	-- 调用gate玩家暂离
	skynet.fork(function()
		-- 调用玩家代理池服务, 玩家登出
		local address = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, self:getKid())
		skynet.send(address, "lua", "afk", self:getUid(), self:getSubid(), 4) --4=链路超时
	end)
end

function player:setFd(fd)
	gLog.i("player:setFd", self.uid, self.subid, "fd=", fd)
    self.fd = fd
	if self.fd and self.fd > 0 then
		if next(self.msgNotify) then
			skynet.fork(function()
				gLog.i("player:setFd send=", self.uid, #self.msgNotify)
				while(true) do
					local c = table.remove(self.msgNotify, 1)
					if c then
						local package = protoLib:s2cEncode(c.cmd, c.msg)
						if not socketdriver.send(self.fd, netpack.pack(package)) then
							gLog.w("player:setFd socketdriver.send", self.uid, self.subid, self.fd)
						end
					else
						break
					end
				end
			end)
		end
	end
end

-- 处理客户端消息
function player:dispatchMsg(cmd, req, rsp)
	if dbconf.DEBUG then
		if cmd ~= "reqHeartbeat" then
			gLog.d("player:dispatchMsg request cmd=", cmd, "args=", table2string(req))
		end
	end
	local _, ret = xpcall(function() -- NOTICE: YIELD here, socket may close.
		local f = assert(clientCmd[cmd], "player:dispatchMsg error, cmd= "..cmd.." is not found")
		if type(f) == "function" then
			return f(self, req or svrFunc.emptyTb)
		end
	end, svrFunc.exception)
	if dbconf.DEBUG then
		if cmd ~= "reqHeartbeat" then
			gLog.d("player:dispatchMsg response cmd=", cmd, "ret=", table2string(ret))
		end
	end
	-- the return subid may change by multi request, check connect
	if rsp and self.fd and self.fd > 0 then
		if not socketdriver.send(self.fd, netpack.pack(rsp(ret or {code = gErrDef.Err_SERVICE_EXCEPTION,}))) then
			gLog.w("player:dispatchMsg socketdriver.send", self.uid, self.subid, self.fd)
		end
	else
		gLog.w("player:dispatchMsg ignore", self.fd, self.uid, "cmd=", cmd, "ret=", table2string(ret))
	end
end

-- 给客户端推送消息
function player:notifyMsg(cmd, msg)
	if self.online == nil then
		gLog.w("player:notifyMsg ignore", self.uid, self.fd, cmd, msg)
		return
	end
	if dbconf.DEBUG then
		gLog.d("player:notifyMsg uid=", self.uid, "cmd=", cmd, "msg=", table2string(msg))
	end
	if self.online then
		if self.fd and self.fd > 0 then
			local package = protoLib:s2cEncode(cmd, msg)
			if not socketdriver.send(self.fd, netpack.pack(package)) then
				gLog.w("player:notifyMsg socketdriver.send", self.uid, self.subid, self.fd)
			end
		else
			table.insert(self.msgNotify, {cmd = cmd, msg = msg,})
		end
	else
		if not self.fd and self.afkTime and self.afkTime > 0 and svrFunc.systemTime() < self.afkTime then -- 暂离30秒内缓存推送消息,客户端断线重连无需重新初始化
			table.insert(self.msgNotify, {cmd = cmd, msg = msg,})
			if #self.msgNotify > 5000 then -- 消息数量过多,报个错,客户端断线重连必须重新初始化
				self.afkTime = nil
				self.msgNotify = {}
			end
		end
	end
end

-- 添加事件(最好cb传函数名称，以方便热更)
function player:registerEvent(eventId, cb, cbobj, params)
	return eventCtrl.registerEvent(eventId, self.uid, cb, cbobj, params)
end

-- 移除事件处理回调
function player:unregisterEvent(h)
	return eventCtrl.unregisterEvent(h)
end

-- 分发事件
function player:dispatchEvent(eventId, ...)
	return eventCtrl.dispatchEvent(eventId, self.uid, ...)
end

-- 热更
function player:hotFix(hotFixes)
	if hotFixes and hotFixes.script then
		self.hotFixes = hotFixes
		self:doHotFix()
	end
end

-- 执行热更
function player:doHotFix()
    if self.hotFixes and self.hotFixes.script then
		gLog.i("player:doHotFix", self.uid, self.hotFixes.script)
		-- local file = require(self.hotFixes.script)
		local filename = string.format("game/service/testService/%s.lua", self.hotFixes.script)
		local s = io.readfile(filename)
		assert(s, "player:doHotFix, filename="..filename)
		local f = load(s, filename, "t")
		assert(f, "player:doHotFix failed, filename="..filename)
		local file = f()
		file.hotFix()
		self.hotFixes = nil
    end
end

return player