--[[
	pvp网关服务中心
]]
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local protoLib = require "protoLib"
local dbconf = require "dbconf"
local svrFunc = require "svrFunc"
local rudpsvr = require("rudpsvr")
local frameLib = require "frameLib"
local serviceCenterBase = require "serviceCenterBase2"
local gatepvpCenter = class("gatepvpCenter", serviceCenterBase)

-- 构造
function gatepvpCenter:ctor()
	self.super.ctor(self)
	-- 套接字对象/服务
	self.socksvr = nil
	-- 消息队列
	self.queue = nil

	-- 模式(1=rudp nil=tcp)
	self.rudp = nil
	-- 客户端连接数
	self.clientNum = 0
	-- 最大客户端连接数
	self.maxClientNum = 4001
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

	-- 随机种子
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
end

-- 停止服务
function gatepvpCenter:stop()
	gLog.i("====gatepvpCenter:stop begin====")

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
	gLog.i("====gatepvpCenter:stop end====")
end

-- 初始化
function gatepvpCenter:init(kid, rudp)
	gLog.i("== gatepvpCenter:init begin ==", kid, rudp)

	-- 王国ID
	self.kid = tonumber(kid)
	-- 模式(1=rudp nil=tcp)
	self.rudp = rudp
	-- 本服地址
	self.addr = skynet.self()
	-- 开启socket监听
	self:openSocket()

	gLog.i("== gatepvpCenter:init end ==")
end

-- tcp/rudp内存回收
function gatepvpCenter:__gc()
	gLog.i("gatepvpCenter:__gc", self.rudp, self.queue)
	if self.rudp then
		if self.socksvr then
			skynet.kill(self.socksvr) --kill rudpsvr
			self.socksvr = nil
		end
	else
		if self.queue then
			netpack.clear(self.queue)
			self.queue = nil
		end
	end
end

-- 杀死服务
function gatepvpCenter:kill()
	gLog.i("== gatepvpCenter:kill ==")
    skynet.exit()
end

-- tcp/rudp开启socket监听
function gatepvpCenter:openSocket()
	gLog.d("gatepvpCenter:openSocket=", self.rudp, self.socksvr)
	local gateConf = require("svrConf"):getGatePvpConf(dbconf.gamenodeid) or {}
	local host, listen, port = gateConf.address, (gateConf.listen or "0.0.0.0"), gateConf.port
	if not (host and listen and port) then
		gLog.w("gatepvpCenter:openSocket ignore, host, listen, port=", host, listen, port)
		return
	end
	if self.rudp then
		if not self.socksvr then
			self.socksvr = skynet.launch("rudpsvr", listen, port, skynet.self()) --launch rudpsvr
			gLog.i("gatepvpCenter:openSocket rudp=", self.rudp, "socksvr=", self.socksvr, "host=", host, "listen=", listen, "port=", port, skynet.self())
			return true
		else
			gLog.e("gatepvpCenter:openSocket error: socket exist")
		end
	else
		if not self.socksvr then
			self.socksvr = socketdriver.listen(listen, port)
			socketdriver.start(self.socksvr)
			gLog.i("gatepvpCenter:openSocket rudp=", self.rudp, "socksvr=", self.socksvr, "host=", host, "listen=", listen, "port=", port)
			return true
		else
			gLog.e("gatepvpCenter:openSocket error: socket exist")
		end
	end
end

-- tcp/rudp关闭socket监听
function gatepvpCenter:closeSocket()
	gLog.i("gatepvpCenter:closeSocket=", self.socksvr)
	if self.rudp then
		if self.socksvr then
			skynet.kill(self.socksvr) --kill rudpsvr
			self.socksvr = nil
		end
	else
		if self.socksvr then
			socketdriver.close(self.socksvr)
			self.socksvr = nil
		end
	end
end

-- tcp/rudp客户端连入
function gatepvpCenter:open(fd, msg)
	if self.rudp then
		gLog.i("gatepvpCenter:open fd=", fd, "msg=", msg)
		-- 检查最大客户端连接数
		if self.clientNum >= self.maxClientNum then
			gLog.e("gatepvpCenter:open error", fd, msg, self.clientNum)
			rudpsvr.rudp_close(fd)
			return false
		end
		self.connection[fd] = fd
		self.clientNum = self.clientNum + 1
		self.handshake[fd] = msg --addr
	else
		gLog.i("gatepvpCenter:open fd=", fd, "msg=", msg)
		-- 检查最大客户端连接数
		if self.clientNum >= self.maxClientNum then
			gLog.e("gatepvpCenter:open error", fd, msg, self.clientNum)
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
end

-- tcp/rudp客户端断开
function gatepvpCenter:close(fd, tag, inSq)
	gLog.i("gatepvpCenter:close", fd, tag, inSq)
	self.handshake[fd] = nil
	if self.connection[fd] then
		self.connection[fd] = nil
		self.clientNum = self.clientNum - 1
		if self.rudp then
			rudpsvr.rudp_close(fd)
		else
			socketdriver.close(fd)
		end
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
function gatepvpCenter:disconnectHandler(fd, username, tag)
	local u = self.usernameMap[username]
	if u and u.fd == fd then
		gLog.i("gatepvpCenter:disconnectHandler enter fd=", fd, "uid=", u.uid, u.subid, tag)
		local time = skynet.time()
		--
		self.uidMap[u.uid] = nil
		self.usernameMap[username] = nil
		-- 调用帧同步服务, 玩家暂离
		frameLib:call(self.kid, u.batId, "afk", u.uid, u.batId, u.subid, 0)
		gLog.i("gatepvpCenter:disconnectHandler end fd=", fd, "uid=", u.uid, u.subid, tag, "time=", skynet.time()-time)
	else
		gLog.i("gatepvpCenter:disconnectHandler ignore fd=", fd, u and u.fd, "uid=", u and u.uid, u and u.subid, tag)
	end
	--gLog.dump(self, "gatepvpCenter:disconnectHandler self=")
end

-- tcp/rudp客户端连入关闭fd
function gatepvpCenter:closeclient(fd)
	if self.rudp then
		local c = self.connection[fd]
		if c then
			self.connection[fd] = nil
			rudpsvr.rudp_close(fd)
		end
	else
		local c = self.connection[fd]
		if c then
			self.connection[fd] = nil
			socketdriver.close(fd)
		end
	end
end

-- tcp分发客户端消息队列
function gatepvpCenter:dispatchQueue()
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

-- tcp/rudp分发客户端消息 peer, ud, buf, sz
function gatepvpCenter:dispatchMsg(fd, msg, sz)
    --gLog.d("gatepvpCenter:dispatchMsg=", fd, msg, sz)
    if self.connection[fd] then
		local addr = self.handshake[fd]
		if addr then -- atomic, not yield
			self:auth(fd, addr, msg, sz)
			self.handshake[fd] = nil
		else
			self:request(fd, msg, sz)
		end
    else
		if self.rudp then
			gLog.w(string.format("gatepvpCenter:dispatchMsg drop message from fd (%s) : %s", fd, msg))
		else
			gLog.w(string.format("gatepvpCenter:dispatchMsg drop message from fd (%d) : %s", fd, netpack.tostring(msg, sz)))
		end
    end
end

-- tcp/rudp认证 atomic, not yield
function gatepvpCenter:auth(fd, addr, msg, sz)
	if self.rudp then
		gLog.i("gatepvpCenter:auth begin, fd=", fd, addr, sz)
		local callok, ok, result, rsp = xpcall(self.doAuth, svrFunc.exception, self, fd, msg, sz, addr)
		if not callok or not ok then
			gLog.w("gatepvpCenter:auth error", fd)
			result = result or {code = gErrDef.Err_CHAT_AUTH_ERR, text = "Bad Request",}
		else
			gLog.i("gatepvpCenter:auth success, fd=", fd, "code=", result.code)
		end
		-- 回包
		if rsp then
			self:sendMsg(fd, result, rsp)
		end
		-- 若认证失败, 则关闭连接
		if not callok or not ok then
			self:close(fd, "gateauth")
		end
	else
		local str = netpack.tostring(msg, sz)
		gLog.i("gatepvpCenter:auth begin, fd=", fd, addr, msg, sz)
		local callok, ok, result, rsp = xpcall(self.doAuth, svrFunc.exception, self, fd, str, sz, addr)
		if not callok or not ok then
			gLog.w("gatepvpCenter:auth error", fd)
			result = result or {code = gErrDef.Err_CHAT_AUTH_ERR, text = "Bad Request",}
		else
			gLog.i("gatepvpCenter:auth success, fd=", fd, "code=", result.code)
		end
		-- 回包
		if rsp then
			self:sendMsg(fd, result, rsp)
		end
		-- 若认证失败, 则关闭连接
		if not callok or not ok then
			self:close(fd, "gateauth")
		end
	end
end

-- tcp/rudp认证 atomic, not yield
function gatepvpCenter:doAuth(fd, msg, sz, addr)
	local callok, tp, cmd, args, rsp = pcall(function () -- 客户端请求解码
		return protoLib:c2sDecode(msg, sz)
	end)
	gLog.dump(args, "gatepvpCenter:doAuth tp="..tostring(tp)..",cmd="..tostring(cmd)..",rsp="..tostring(rsp)..",args=")
	if not callok or cmd ~= "reqPvpHandshake" or not args or not args.uid or not args.index or not args.hmac or not args.batId or not rsp then
		gLog.w("gatepvpCenter:doAuth error0", fd, callok, tp, cmd, rsp, table2string(args))
		return false, {code = 401, text = "401 unauthorized",}, rsp
	end
	local uid, index, hmac = args.uid, args.index, args.hmac
	-- 验证
	local text = string.format("%s:%s", uid, index)
	local v = crypt.base64encode(crypt.hmac_sha1(dbconf.secret, text))
	if v ~= hmac then
		gLog.w("gatepvpCenter:doAuth error1", fd, uid, v, "hmac=", hmac)
		return false, {code = gErrDef.Err_CHAT_AUTH_ERR, text = "401 unauthorized",}, rsp
	end
	-- 登录
	if index == 1 then
		local _,code = self:login(uid, args.batId)
		if code then
			gLog.w("gatepvpCenter:doAuth error2", fd, uid, index, code)
			return false, {code = gErrDef.Err_CHAT_AUTH_ERR, text = "not found",}, rsp
		end
	end
	-- 是否已登录
	gLog.i("gatepvpCenter:doAuth fd=", fd, "uid=", uid, "index=", index)
	local u = self.uidMap[uid]
	if not u then
		gLog.w("gatepvpCenter:doAuth error3", fd, uid, index)
		return false, {code = gErrDef.Err_CHAT_AUTH_ERR, text = "not found",}, rsp
	end
	local sq = self:getSq(u.uid)
	return sq(function()
		-- 连接检查版本号
		if index <= u.version then
			gLog.w("gatepvpCenter:doAuth error4", fd, uid, index, u.version)
			return false, {code = gErrDef.Err_CHAT_AUTH_ERR, text = "forbidden",}, rsp
		end
		-- 补充玩家信息
		u.fd = fd
		u.version = index
		u.addr = addr
		self.connectionMap[fd] = u
		-- 补充agent信息
		local ok = skynet.call(u.agent, "lua", "setFd", fd, uid, u.subid)
		assert(ok == true)
		gLog.i("gatepvpCenter:doAuth success fd=", fd, "uid=", u.uid, u.batId, u.subid)
		--
		return true, {code = gErrDef.Err_OK, text = "OK", subid = u.subid,}, rsp
	end)
end

-- 处理消息 not atomic, may yield
function gatepvpCenter:request(fd, msg, sz)
	--gLog.d("gatepvpCenter:request", fd, msg, sz)
	local ok, err = pcall(self.doRequest, self, fd, msg, sz)
	if not ok then
		gLog.w("gatepvpCenter:request error: invalid package", fd, err, msg, sz)
		if self.connection[fd] then
			self:close(fd, "gaterequest")
		end
	end
end

-- 处理消息
function gatepvpCenter:doRequest(fd, msg, sz)
	local u = assert(self.connectionMap[fd], string.format("gatepvpCenter:doRequest error: invalid fd=%s", fd))
	if self.rudp then
		skynet.redirect(u.agent, self.addr, "client", 0, skynet.pack(fd, msg, sz))
	else
		skynet.redirect(u.agent, self.addr, "client", 0, skynet.pack(fd, netpack.tostring(msg, sz)))
	end
end

-- 登陆(只允许单机登陆)
function gatepvpCenter:login(uid, batId)
	local sq = self:getSq(uid)
	return sq(function ()
		gLog.i("gatepvpCenter:login enter uid=", uid, batId)
		local time = skynet.time()
		-- 玩家已在线
		local u = self.uidMap[uid]
		if u then
			gLog.w("gatepvpCenter:login error1=", uid, batId, "u=", table2string(u))
			local batId_, username_, subid_, fd_ = u.batId, u.username, u.subid, u.fd
			self.uidMap[uid] = nil
			self.usernameMap[username_] = nil
			-- 调用帧同步服务, 玩家登出
			frameLib:call(self.kid, batId_, "afk", uid, batId_, subid_, 1) -- 1=抢号踢出
			-- 断开连接
			if fd_ then
				self:close(fd_, "gatelogin", true)
			end
		end
		-- 玩家登陆
		self.internalId = self.internalId + 1
		local subid = self.internalId
		local username = self:usernameEncode(uid, subid)
		-- 调用帧同步服务, 玩家登陆
		gLog.i("gatepvpCenter:login call agent=", uid, subid, username)
		local agent, code = frameLib:call(self.kid, batId, "login", uid, batId, subid)
		if type(agent) ~= "number" then
			assert(code, string.format("gatepvpCenter:login error2: uid=%s subid=%s", uid, subid))
			return nil, code
		end
		-- 登录成功
		local u = 
		{
			username = username,
			agent = agent,	-- 帧同步服务地址
			batId = batId,	-- 战场ID
			uid = uid,
			subid = subid,
			version = 0, 	-- 连接网关版本号
			fd = 0, 		-- socket fd
			addr = nil, 	-- 地址
		}
		self.uidMap[uid] = u
		self.usernameMap[username] = u
		gLog.i("gatepvpCenter:login success=", uid, subid, username, "time=", skynet.time()-time)
		-- you should return unique subid
		return subid
	end)
end

-- 暂离(flag:0=断网 1=战场结束
function gatepvpCenter:afk(uid, subid, flag)
	local sq = self:getSq(uid)
	sq(function()
		local time = skynet.time()
		local u = self.uidMap[uid]
		gLog.i("gatepvpCenter:afk enter uid=", uid, subid, flag)
		if u and u.fd then -- 已afk则设置u.fd=nil
			local fd = u.fd
			u.fd = nil
			local username = self:usernameEncode(uid, subid)
			if u.username ~= username and subid > u.subid then --若u.subid更大, 则说明已建立新连接, 旧afk不能导致新连接afk
				gLog.w("gatepvpCenter:afk error, u.username ~= username", uid, subid, u.subid, "fd=", fd)
				self.uidMap[uid] = nil
				self.usernameMap[username] = nil
				self.usernameMap[u.username] = nil
			end
			self.uidMap[uid] = nil
			self.usernameMap[username] = nil
			-- 调用帧同步服务, 玩家登出
			frameLib:call(self.kid, u.batId, "afk", uid, u.batId, u.subid, flag or 0)
			-- 断开连接
			if fd then
				self:close(fd, "gateafk", true)
			end
			gLog.i("gatepvpCenter:afk success=", uid, subid, flag, "fd=", fd, "time=", skynet.time()-time)
		else
			gLog.w("gatepvpCenter:afk ignore=", uid, subid, flag)
		end
	end)
	self:delSq(uid)
	--gLog.dump(self, "gatepvpCenter:afk self="..tostring(uid))
end

-- username编码
function gatepvpCenter:usernameEncode(uid, subid)
	return string.format("%s@%s", uid, subid)
end

-- tcp/rudp发送消息(json协议)
function gatepvpCenter:sendMsg(fd, result, rsp)
	if self.rudp then
		--gLog.d("gatepvpCenter:sendMsg=", self.socksvr, fd, table2string(result))
		rudpsvr.rudp_send(fd, rsp(result))
	else
		--gLog.d("gatepvpCenter:sendMsg=", self.socksvr, fd, table2string(result))
		socketdriver.send(fd, netpack.pack(rsp(result)))
	end
end

return gatepvpCenter