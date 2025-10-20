--[[
	连接游戏网关服登录
]]
local crypt = require "client.crypt"
local lfs = require("lfs")
local dbconf = require("dbconf")
local socket = require("client.socket")
local sproto = require "sproto"
local sprotoparser = require "sprotoparser"
local json = require "json"
local simSocket = require("simSocket")
local simGate = class("simGate", simSocket)

-- 定义事件
simGate.Gate_Success = "Gate_Success" -- 连接游戏服网关成功事件, 下面开始处理业务

-- 网关相关错误类型
simGate.Err_Gate_HandshakeSuccess = 0 --网关握手成功

-- 状态
local eGateStatus =
{
	handshake = 0,	--握手状态, 客户端发起握手包, 服务器回应
	logined = 1, 	--登录状态, 客户端发起业务包, 服务器回应
}

-- 构造
function simGate:ctor()
	simGate.super.ctor(self, "simGate")

	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

	self.rudp = nil  		-- 模式(1=rudp nil=tcp)
	self.index = 0 		-- 连接版本号, 需要>=1, 每次连接都需要比之前的大, 这样可以保证握手包不会被人恶意截获复用
	self.sessionid = 0	-- 请求编号, 防止恶意截获复用
	self.uid = nil		-- uid
	self.session = {}

	self.status = eGateStatus.handshake

	self.last = "" --上次的socket数据缓存

	self.sproto_host = nil    -- sproto
	self.sproto_request = nil -- sproto

	self.i = 0

	self:init()
end

-- 初始化
function simGate:init()
	--print("simGate:init begin==")
	-- c2s客户端到服务端的协议
	local c2sFiles = {"types.sproto",}
	for fileName in lfs.dir("game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.c2s.sproto$") then
			table.insert(c2sFiles, fileName)
		end
	end
	local c2sSproto = ""
	for _,fileName in pairs(c2sFiles) do
		c2sSproto = c2sSproto.."\n"..io.readfile("game/service/proto/sproto/"..fileName)
	end
	--print("simGate:init c2sSproto=", c2sSproto)
	local c2sPb = assert(sprotoparser.parse(c2sSproto))
	-- s2c服务端到客户端的协议
	local s2cFiles = {"types.sproto",}
	for fileName in lfs.dir("game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.s2c.sproto$") then
			table.insert(s2cFiles, fileName)
		end
	end
	local s2cSproto = ""
	for _,fileName in pairs(s2cFiles) do
		s2cSproto = s2cSproto.."\n"..io.readfile("game/service/proto/sproto/"..fileName)
	end
	--print("simGate:init s2cSproto=", s2cSproto)
	local s2cPb = assert(sprotoparser.parse(s2cSproto))
	self.sproto_host = sproto.new(s2cPb):host("package")
	self.sproto_request = self.sproto_host:attach(sproto.new(c2sPb))
	--print("simGate:init end")
end

-- 连接网关
function simGate:connectGate(host, port)
    --print("simGate:connectGate host=", host, "port=", port)
	self.index = self.index + 1
	self.status = eGateStatus.handshake
	self:connect(host, port)
end

-- @override 连接成功
function simGate:onConnected()
	--print("simSocket:onConnected", self.name, self.host, self.port, self.fd, self.connected)
	self:dispatchEvent({name = simGate.Gate_Success})
	while(true) do
		local r = self:recv()
		if r then
			self:handleMsg(r)
		elseif self.connected then
			socket.usleep(10000) --0.01s
		else
			print("simGate:onConnected break, sockect close!", self.name)
			break
		end
		local line = socket.readstdin()
		if line then
			self:handleCmd(line)
		end
	end
	self:onFailure()
end

-- @override 连接网关服务器失败
function simGate:onFailure()
	print("simGate:onFailure")
    self:close()
	self.last = ""
end

-- 握手
function simGate:handshake(uid)
	local text = string.format("%s:%s", uid, self.index)
	local hmac = crypt.base64encode(crypt.hmac_sha1(dbconf.secret, text))
	self.sessionid = 0
	self.uid = uid
	local batId = nil -- 生成战场id
	if self.uid%2 == 1 then
		batId = tostring(self.uid)
	else
		batId = tostring(self.uid-1)
	end
	self:request("reqPvpHandshake", {uid = uid, index = self.index, hmac = hmac, batId=batId})
end

-- 握手回包处理
function simGate:handshakeRsp(msg)
	local _, t, sessionid, rsp = pcall(function()
		return self.sproto_host:dispatch(msg)
	end)
	print("simGate:handshakeRsp sessionid=", sessionid, "rsp=", table2string(rsp))
	local cmd = self.session[sessionid] and self.session[sessionid].cmd
	local code = rsp.code
	if cmd == "reqPvpHandshake" and code == simGate.Err_Gate_HandshakeSuccess then
		print("simGate:handshakeRsp success, code=", code, rsp.subid, "text=", rsp.text, "\n")
		self.status = eGateStatus.logined
		-- 关闭心跳
		if not self.rudp then
			self:request("reqPvpHeartbeat")
			self:request("reqPvpHeartbeatSwitch", {close = true,})
		end
		-- 创建房间
		local batId, vsuid = nil, nil -- 生成战场id
		if self.uid%2 == 1 then
			batId = tostring(self.uid)
			vsuid = self.uid + 1
		else
			batId = tostring(self.uid-1)
			vsuid = self.uid - 1
		end
		self.batId = batId
		self:request("reqCreateBattle", {batId=batId,users={[self.uid]={uid=self.uid,camp=0},[vsuid]={uid=vsuid,camp=1}},rate=16,time=86400,})
		-- 请求准备完成
		self:request("reqPrepare", {batId=batId,})
		-- 请求加载场景完成
		self:request("reqLoad", {batId=batId,})
	else
		-- 网关握手失败, 登录失败
		print("simGate:handshakeRsp fail", cmd, code, rsp.text)
		-- 如果业务拒绝断开连接防止界面一直登陆死循环
		self:onFailure()
	end
end

----------------------------------------
-- 数据解包处理和打包
----------------------------------------
-- @override 处理消息
function simGate:handleMsg(r)
	if self.rudp then
		self:dispatchMsg(r)
	else
		local left = r
		if self.last then
			left = self.last..r
		end
		while true do
			local msg
			msg, left = self:unpackMsg(left)
			if msg then
				self:dispatchMsg(msg)
			else
				break
			end
			if not left then
				break
			end
		end
		self.last = left
	end
end

-- 解包消息, 数据包 = 头部2字节size+协议数据
function simGate:unpackMsg(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s + 2 then
		return nil, text --msg, left(result已经把size去掉了)
	end
	return text:sub(3, 2 + s), text:sub(3 + s)
end

-- 处理消息
function simGate:dispatchMsg(msg)
	if self.status == eGateStatus.handshake then
		self:handshakeRsp(msg)
	else
		local _, t, sessionid, rsp = pcall(function()
			return self.sproto_host:dispatch(msg)
		end)
		local cmd = self.session[sessionid] and self.session[sessionid].cmd or sessionid
		if cmd == "notifyPvpCmd" then
			if next(rsp.fs) then
				print("simGate:dispatchMsg receive cmd=", cmd, "rsp batId=", rsp.batId, "uid=", self.uid, "f=", rsp.f)
			end
			self.i = rsp.f
			if self.i%16 == 0 then
				self:request("reqCommitCmd", {batId=self.batId, cmd={f=1,tp=self.i,str=[[
Mark Scheflen told to the VOA correspondent that potential participants of the project have been required to xxx.
				]]}})
			end
		else
			if cmd ~= "reqCommitCmd" and cmd ~= "notifyPvpInfo" then
				print("simGate:dispatchMsg receive cmd=", cmd, "rsp=", table2string(rsp))
			end
		end
		if sessionid then
			self.session[sessionid] = nil
		end
	end
end

--eg: reqHeartbeat time=1665283633
function simGate:handleCmd(line)
	--print("simGate:handleCmd line=", line)
	local cmd
	local p = string.gsub(line, "([%w-_]+)", function (s)
		cmd = s
		return ""
	end, 1)
	local t = {}
	local f = load (p, "=" .. cmd, "t", t)
	if f then
		f()
	end
	if not next (t) then
		t = nil
	end
	if cmd then
		local ok, err = pcall(self.request, self, cmd, t)
		if not ok then
			print(string.format("invalid command (%s), error (%s)", cmd, err))
		end
	end
end

-- 发送消息
function simGate:request(cmd, args)
	--print("simGate:request cmd=", cmd, "args=", table2string(args))
	self.sessionid = self.sessionid + 1
	if self.sessionid >= 2147483647 then -- 超过int32最大值, 重新开始
		self.sessionid = 1
	end
	--print("simGate:request sn=", self.sessionid, "cmd=", cmd, "data=", table2string(args))
	self.session[self.sessionid] = {cmd = cmd, args = args,}
	local package = self.sproto_request(cmd, args, self.sessionid)
	if self.rudp then
		self:send(package)
	else
		self:send(string.pack(">s2", package))
	end
end

return simGate
