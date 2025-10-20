--[[
	网关服务中心(断线重连: 登录服login)
]]
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local protoLib = require "protoLib"
local dbconf = require "dbconf"
local svrAddrMgr = require "svrAddrMgr"
local svrFunc = require "svrFunc"
local svrConf = require "svrConf"
local initDBConf = require "initDBConf"
local serviceCenterBase = require "serviceCenterBase2"
local gateCenter = class("gateCenter", serviceCenterBase)

-- 构造
function gateCenter:ctor()
	self.super.ctor(self)
	-- 监听的socket对象
	self.socket = nil
	-- 消息队列
	self.queue = nil

	-- 客户端连接数
	self.clientNum = 0
	-- 最大客户端连接数
	self.maxClientNum = 65535
	-- 是否无延迟
	self.nodelay = true

	-- 玩家信息
	self.uidMap = {}
	-- 玩家信息
	self.usernameMap = {}
	-- 玩家连接信息
	self.connection = {}
	self.connectionMap = {}
	self.handshake = {}
	-- 自增内部ID
	self.internalId = 0

	-- 是否与登录服务器心跳连接
	self.heartbeat = false

	-- 随机种子
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
end

-- 停止服务
function serviceCenterBase:stop()
	gLog.i("====gateCenter:stop begin====")
	-- 标记停服中
	if self.stoping or self.stoped then
		return
	end
	self.stoping = true
	-- 标记已停服
	self.stoped = true
	if self.myTimer then
		self.myTimer:pause()
	end
	--
	local loginConf = initDBConf:getLoginConf()
	for k,v in pairs(loginConf) do
		pcall(function()
			local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
			skynet.send(loginMasterSvr, "lua", "unregisterGate", dbconf.gamenodeid)
		end)
	end
	gLog.i("====gateCenter:stop end====")
end

-- 内存回收
function gateCenter:__gc() 
	gLog.i("gateCenter:__gc", self.queue)
	if self.queue then
		netpack.clear(self.queue)
		self.queue = nil
	end
end

-- 杀死服务
function gateCenter:kill()
	gLog.i("== gateCenter:kill ==")
    skynet.exit()
end

-- 初始化
function gateCenter:init()
	gLog.i("== gateCenter:init begin ==")

	-- 开启socket监听
	self:openSocket()

	gLog.i("== gateCenter:init end ==")
end

-- 开启socket监听
function gateCenter:openSocket()
	gLog.i("gateCenter:openSocket=", self.socket)
	if not self.socket then
		local gateConf = svrConf:gateConfGame(dbconf.gamenodeid)
		local host, listen, port = gateConf.address, (gateConf.listen or "0.0.0.0"), gateConf.port
		assert(port, "gateCenter:openSocket error: listen or port invalid!")
		self.socket = socketdriver.listen(listen, port)
		gLog.i("gateCenter:openSocket, host, listen, port, socket=", host, listen, port, self.socket)
		socketdriver.start(self.socket)
		-- 游戏服网关OPEN后向登录服注册网关服务代理
		-- self:registerGate()
		return true
	else
		gLog.e("gateCenter:openSocket error: socket exist")
	end
end

-- 关闭socket监听
function gateCenter:closeSocket()
	gLog.i("gateCenter:closeSocket=", self.socket)
	if self.socket then
		socketdriver.close(self.socket)
		self.socket = nil
	end
end

-- 客户端连入
function gateCenter:open(fd, msg)
	gLog.i("gateCenter:open fd=", fd)
	-- 检查最大客户端连接数
	if self.clientNum >= self.maxClientNum then
		gLog.e("gateCenter:open error", fd)
		socketdriver.close(fd)
		return false
	end
	if self.nodelay then
        socketdriver.nodelay(fd)
    end
    
    self.connection[fd] = fd
    self.clientNum = self.clientNum + 1
    self.handshake[fd] = msg --addr

    -- 开启套接字
    socketdriver.start(fd)
end

-- 客户端断开
function gateCenter:close(fd, tag, inSq)
	gLog.i("gateCenter:close", fd, tag, inSq)
	self.handshake[fd] = nil
	if self.connection[fd] then
    	self.connection[fd] = nil
    	self.clientNum = self.clientNum - 1
    	socketdriver.close(fd)
    end
	local u = self.connectionMap[fd]
	if u then
		self.connectionMap[fd] = nil
		if inSq then
			self:disconnectHandler(fd, u.username, tag)
		else
			local sq = self:getSq(u.uid)
			sq(function ()
				self:disconnectHandler(fd, u.username, tag)
			end)
			self:delSq(u.uid)
		end
	end
end

-- 客户端断开处理
function gateCenter:disconnectHandler(fd, username, tag)
	local u = self.usernameMap[username]
	if u and u.fd == fd then
		gLog.i("gateCenter:disconnectHandler enter fd=", fd, "uid=", u.uid, u.subid, tag)
		local time = skynet.time()
		--
		self.uidMap[u.uid] = nil
		self.usernameMap[username] = nil
		-- 调用登录服, 玩家登出
		local loginConf = initDBConf:getLoginConf()
		for k,v in pairs(loginConf) do
			pcall(function()
				local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
				skynet.call(loginMasterSvr, "lua", "logout", u.uid, u.subid)
			end)
		end
		-- 调用玩家代理池服务, 玩家暂离
		local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, u.kid)
		skynet.call(agentPoolSvr, "lua", "afk", u.uid, u.subid, 0) --0.断网
		gLog.i("gateCenter:disconnectHandler end fd=", fd, "uid=", u.uid, u.subid, tag, "time=", skynet.time()-time)
	else
		gLog.i("gateCenter:disconnectHandler ignore fd=", fd, u and u.fd, "uid=", u and u.uid, u and u.subid, tag)
	end
	--gLog.dump(self, "gateCenter:disconnectHandler self=")
end

-- 客户端连入关闭fd
function gateCenter:closeclient(fd)
	local c = self.connection[fd]
	if c then
		self.connection[fd] = nil
		socketdriver.close(fd)
	end
end

-- 分发客户端消息队列
function gateCenter:dispatchQueue()
    local fd, msg, sz = netpack.pop(self.queue)
    if fd then
        -- may dispatch even the message blocked
        -- If the message never block, the queue should be empty, so only fork once and then exit.
        skynet.fork(function ()
        	self:dispatchQueue()
        end)

        self:dispatchMsg(fd, msg, sz)

        for fd, msg, sz in netpack.pop, self.queue do
            self:dispatchMsg(fd, msg, sz)
        end
    end
end

-- 分发客户端消息
function gateCenter:dispatchMsg(fd, msg, sz)
    --gLog.d("gateCenter:dispatchMsg=", fd, sz)
    if self.connection[fd] then
		local addr = self.handshake[fd]
		if addr then -- atomic, not yield
			self:auth(fd, addr, msg, sz)
			self.handshake[fd] = nil
		else
			self:request(fd, msg, sz)
		end
    else
        gLog.w(string.format("gateCenter:dispatchMsg Drop message from fd (%d) : %s", fd, netpack.tostring(msg, sz)))
    end
end

-- 认证 atomic, not yield
function gateCenter:auth(fd, addr, msg, sz)
	local str = netpack.tostring(msg, sz)
	--gLog.d("gateCenter:auth begin, fd=", fd, addr, str)
	local callok, ok, result, rsp = xpcall(self.doAuth, svrFunc.exception, self, fd, str, sz, addr)
	if not callok then
		gLog.w("gateCenter:auth error1", fd)
		result = result or {code = 400, text = "400 Bad Request",}
	elseif not ok then
		gLog.w("gateCenter:auth error2", fd)
		result = result or {code = 400, text = "400 Bad Request",}
	else
		gLog.i("gateCenter:auth success, fd=", fd, "result=", result.code)
	end
	-- 回包
	if rsp then
		socketdriver.send(fd, netpack.pack(rsp(result)))
	end
	-- 若认证失败, 则关闭连接
	if not callok or not ok then
		self:close(fd, "gateauth")
	end
end

-- 认证 atomic, not yield
function gateCenter:doAuth(fd, msg, sz, addr)
	local callok, tp, cmd, args, rsp = pcall(function () -- 客户端请求解码
		return protoLib:c2sDecode(msg, sz)
	end)
	--gLog.dump(args, "gateCenter:doAuth tp="..tp..",cmd="..cmd..",rsp="..tostring(rsp)..",args=")
	if self.stoped or not callok or cmd ~= "reqHandshake" or not args or not args.text or not rsp then
		gLog.w("gateCenter:doAuth error1", fd, callok, tp, cmd, args, rsp)
		return false, {code = 401, text = "401 unauthorized",}, rsp
	end
	local username, index, hmac = string.match(args.text, "([^:]*):([^:]*):([^:]*)")
	gLog.i("gateCenter:doAuth fd=", fd, "text=", args.text, "addr=", addr, "username=", username, "index=", index, "hmac=", hmac)
	-- 是否已登录
	local u = self.usernameMap[username]
	if not u then
		gLog.w("gateCenter:doAuth error2", fd)
		return false, {code = 404, text = "404 not found",}, rsp
	end
	local sq = self:getSq(u.uid)
	return sq(function()
		-- 连接检查版本号
		index = tonumber(index)
		if not index or index <= u.version then
			gLog.w("gateCenter:doAuth error3", fd, index, u.version)
			return false, {code = 403, text = "403 forbidden",}, rsp
		end
		-- 验证
		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac64(crypt.hashkey(text), u.secret)
		if crypt.base64encode(v) ~= hmac then
			gLog.w("gateCenter:doAuth error5", fd, crypt.base64decode(v), "hmac=", hmac)
			return false, {code = 401, text = "401 unauthorized",}, rsp
		end
		-- 补充玩家信息
		u.fd = fd
		u.version = index
		u.addr = addr
		self.connectionMap[fd] = u
		-- 补充agent信息
		skynet.send(u.agent, "lua", "setFd", fd)
		gLog.i("gateCenter:doAuth success fd=", fd, "uid=", u.uid)
		--
		return true, {code = 200, text = "200 OK",}, rsp
	end)
end

-- 处理消息 not atomic, may yield
function gateCenter:request(fd, msg, sz)
	--gLog.d("gateCenter:request", fd, msg, sz)
	local ok, err = pcall(self.doRequest, self, fd, msg, sz)
	if not ok then
		gLog.w("gateCenter:request error: invalid package", fd, err, sz)
		if self.connection[fd] then
			self:close(fd, "gaterequest")
		end
	end
end

-- 处理消息
function gateCenter:doRequest(fd, msg, sz)
	local u = assert(self.connectionMap[fd], string.format("gateCenter:doRequest error: invalid fd=%s", fd))
	skynet.redirect(u.agent, skynet.self(), "client", 0, msg, sz)
end

-- 获取服务名
function gateCenter:svrName()
	return svrAddrMgr.getSvrName(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
end

-- 游戏服网关OPEN后向登录服注册网关服务代理
function gateCenter:registerGate()
	if self.heartbeat and not self.stoped then
		local loginConf = initDBConf:getLoginConf()
		for k,v in pairs(loginConf) do
			pcall(function ()
				local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
				skynet.send(loginMasterSvr, "lua", "registerGate", dbconf.gamenodeid, self:svrName())
			end)
		end
	end
end

-- 游戏服网关OPEN后向登录服发送心跳
function gateCenter:heartbeat2LoginSvr()
	self.heartbeat = true
	self:registerGate()
	-- 间隔13s
	skynet.timeout(3300, function()
		self:heartbeat2LoginSvr()
	end)
end

-- 更新服务器配置
function gateCenter:refreshDBConf()
	gLog.i("gateCenter:refreshDBConf")
	initDBConf:set(true)
	return true
end

-- 登陆(由登陆服调用, 此时玩家尚未连接网关, 只允许单机登陆)
function gateCenter:login(uid, kid, isNew, secret, version, plateform, model, addr)
	local sq = self:getSq(uid)
	return sq(function ()
		gLog.i("gateCenter:login enter uid=", uid, kid, isNew, secret, version, plateform, model, addr)
		local time = skynet.time()
		-- 玩家已在线
		local u = self.uidMap[uid]
		if u then
			gLog.w("gateCenter:login error=", uid, kid, isNew, secret, version, plateform, model, addr, "uidMap=", table2string(u))
			local kid_, username_, subid_, fd_ = u.kid, u.username, u.subid, u.fd
			self.uidMap[uid] = nil
			self.usernameMap[username_] = nil
			-- 调用登录服, 玩家登出
			local loginConf = initDBConf:getLoginConf()
			for k,v in pairs(loginConf) do
				pcall(function()
					local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
					skynet.call(loginMasterSvr, "lua", "logout", uid, subid_)
				end)
			end
			-- 调用玩家代理池服务, 玩家登出
			local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, kid_)
			skynet.call(agentPoolSvr, "lua", "afk", uid, subid_, 1) --skynet.call(agentPoolSvr, "lua", "logout", uid, subid_, "gatelogin")
			-- 断开连接
			if fd_ then
				self:close(fd_, "gatelogin", true)
			end
			-- 中断本次登录
			error(string.format("gateCenter:login error: user is already login, uid=%d kid=%d subid=%d", uid, kid, subid_))
		end
		-- 玩家登陆
		self.internalId = self.internalId + 1
		local subid = self.internalId
		local username = self:usernameEncode(uid, dbconf.gamenodeid, subid)
		-- 调用玩家代理池服务, 玩家登陆
		gLog.i("gateCenter:login call agent pool=", uid, dbconf.gamenodeid, subid, username)
		local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, kid)
		local agent, isInit = skynet.call(agentPoolSvr, "lua", "login", skynet.self(), uid, subid, kid, isNew, version, plateform, model, addr)
		if type(agent) ~= "number" then
			error(string.format("gateCenter:login error3: uid=%s kid=%s subid=%s", uid, subid, kid))
		end
		-- 登录成功
		local u = 
		{
			username = username,
			agent = agent,	-- 玩家agent地址
			uid = uid,
			kid = kid,
			subid = subid,
			secret = secret,
			version = 0, 	-- 连接网关版本号
			index = 0, 		-- 请求索引
			response = {},	-- response cache
			fd = 0, 		-- socket fd
			addr = nil, 	-- 地址
		}
		self.uidMap[uid] = u
		self.usernameMap[username] = u
		gLog.i("gateCenter:login success=", uid, subid, username, "isInit=", isInit, "time=", skynet.time()-time)
		-- you should return unique subid
		return subid, isInit
	end)
end

-- 暂离(flag:0=断网(本gate调用) 1=抢号踢出(login调用) 2=请求afk(agent调用) 4=链路超时(agentpool调用))
function gateCenter:afk(uid, subid, flag)
	local sq = self:getSq(uid)
	sq(function()
		local time = skynet.time()
		local u = self.uidMap[uid]
		gLog.i("gateCenter:afk enter uid=", uid, subid, flag)
		if u and u.fd then -- 已afk则设置u.fd=nil
			local fd = u.fd
			u.fd = nil
			local username = self:usernameEncode(uid, dbconf.gamenodeid, subid)
			if subid and u.username ~= username and subid > u.subid then --若u.subid更大, 则说明已建立新连接, 旧afk不能导致新连接afk
				gLog.w("gateCenter:afk error, u.username ~= username", uid, subid, u.subid, "fd=", fd)
				self.uidMap[uid] = nil
				self.usernameMap[u.username] = nil
				self.usernameMap[username] = nil
				-- 调用登录服, 玩家登出
				local loginConf = initDBConf:getLoginConf()
				for k,v in pairs(loginConf) do
					pcall(function()
						local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
						skynet.call(loginMasterSvr, "lua", "logout", uid, u.subid)
					end)
				end
				-- 调用玩家代理池服务, 玩家登出
				if flag ~= 4 then
					local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, u.kid)
					skynet.call(agentPoolSvr, "lua", "afk", uid, u.subid, flag or 0)
				end
				-- 断开连接
				if fd then
					self:close(fd, "gateafk", true)
				end
				-- 中断本次踢出
				error(string.format("gateCenter:afk afk: u.username ~= usernam, uid=%d subid=%d %d", uid, subid, u.subid))
			end
			self.uidMap[uid] = nil
			self.usernameMap[username] = nil
			-- 调用登录服, 玩家登出
			local loginConf = initDBConf:getLoginConf()
			for k,v in pairs(loginConf) do
				pcall(function()
					local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
					skynet.call(loginMasterSvr, "lua", "logout", uid, u.subid)
				end)
			end
			-- 调用玩家代理池服务, 玩家登出
			if flag ~= 4 then
				local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, u.kid)
				skynet.call(agentPoolSvr, "lua", "afk", uid, u.subid, flag or 0)
			end
			-- 断开连接
			if fd then
				self:close(fd, "gateafk", true)
			end
			gLog.i("gateCenter:afk success=", uid, subid, flag, "fd=", fd, "time=", skynet.time()-time)
		else
			gLog.w("gateCenter:afk ignore=", uid, subid, flag)
		end
	end)
	self:delSq(uid)
	--gLog.dump(self, "gateCenter:afk self=")
end

-- 登出(销毁agent, agent调用() 或 agentpool)
function gateCenter:logout(uid, subid, flag)
	local sq = self:getSq(uid)
	sq(function ()
		local time = skynet.time()
		local u = self.uidMap[uid]
		gLog.i("gateCenter:logout enter uid=", uid, subid, flag, u and u.fd)
		if u then
			local username = self:usernameEncode(uid, dbconf.gamenodeid, subid)
			if subid and u.username ~= username then
				gLog.e("gateCenter:logout error, u.username ~= username", uid, subid, flag, username, u.username)
				self.uidMap[uid] = nil
				self.usernameMap[u.username] = nil
				self.usernameMap[username] = nil
				-- 调用登录服, 玩家登出
				local loginConf = initDBConf:getLoginConf()
				for k,v in pairs(loginConf) do
					pcall(function()
						local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
						skynet.call(loginMasterSvr, "lua", "logout", uid, u.subid)
					end)
				end
				-- 调用玩家代理池服务, 玩家登出
				if flag ~= 4 then
					local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, u.kid)
					skynet.call(agentPoolSvr, "lua", "logout", uid, u.subid, "gatelogout")
				end
				-- 断开连接
				if u.fd then
					self:close(u.fd, "gatelogout", true)
				end
				-- 中断本次登出
				error("gateCenter:logout error, u.username ~= username")
			end
			-- 玩家登出
			self.uidMap[uid] = nil
			self.usernameMap[username] = nil
			-- 调用登录服, 玩家登出
			local loginConf = initDBConf:getLoginConf()
			for k,v in pairs(loginConf) do
				pcall(function()
					local loginMasterSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.loginMasterSvr)
					skynet.call(loginMasterSvr, "lua", "logout", uid, subid)
				end)
			end
			-- 调用玩家代理池服务, 玩家登出
			if flag ~= 4 then
				local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, u.kid)
				skynet.call(agentPoolSvr, "lua", "logout", uid, subid, "gatelogout")
			end
			-- 断开连接
			if u.fd then
				self:close(u.fd, "gatelogout", true)
			end
			gLog.i("gateCenter:logout end uid=", uid, subid, flag, "time=", skynet.time()-time)
		else
			gLog.w("gateCenter:logout ignore uid=", uid, subid, flag)
		end
	end)
	self:delSq(uid)
	--gLog.dump(self, "gateCenter:logout self=")
end

-- username解码
function gateCenter:usernameDecode(username)
	local uid, nodeid, subid = username:match("([^@]*)@([^#]*)#(.*)")
	return crypt.base64decode(uid), crypt.base64decode(nodeid), crypt.base64decode(subid)
end

-- username编码
function gateCenter:usernameEncode(uid, nodeid, subid)
	return string.format("%s@%s#%s", crypt.base64encode(uid), crypt.base64encode(nodeid), crypt.base64encode(tostring(subid)))
end

-- call by agent
function gateCenter:stat()
	local num = table.nums(self.usernameMap)
	gLog.i("gateCenter:stat num=", num)
	return num
end

-- 字符串转换
function gateCenter:exchangeKeys(mkeys)
	local ret = {}
	if type(mkeys) == "string" then
		local length = string.len(mkeys)
		for i = 1, length, 1 do
			local ascii = string.byte(mkeys, i)
			if i % 2 == 0 then
				ascii = ascii + 1 --简单加1
			else
				ascii = ascii - 1 --简单减1
			end
			ret[i] = string.char(ascii)
		end
	end
	return table.concat(ret)
end

-- [废弃]发送消息(json协议)
function gateCenter:sendMsg(fd, session, msg)
    local result = require("json").encode(msg) or ""
    gLog.d("gateCenter:sendMsg fd=", fd, result)

    -- 大端打包: 头部2字节+数据+4字节session
    result = result .. string.pack(">BI4", 1, session)
    local pack = string.pack(">s2", result)

    -- 下发数据
    gLog.d("gateCenter:sendMsg fd=", fd, "pack=", pack)
    socketdriver.send(fd, pack)
end

return gateCenter