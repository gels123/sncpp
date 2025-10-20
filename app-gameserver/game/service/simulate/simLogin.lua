--[[
	连接登录服登录
]]
local crypt = require("client.crypt")
local simSocket = require("simSocket")
local simLogin = class("simLogin", simSocket)

-- 定义事件
simLogin.Login_Success = "Login_Success" --连接登录服成功

-- 错误定义
simLogin.Err_Login_AuthTokenSuccess = 200 --token认证成功
simLogin.Err_Login_HandshakeFailed = 400 --登录握手失败
simLogin.Err_Login_Unauthorized = 401 --自定义的auth_handler不认可token
simLogin.Err_Login_Forbidden = 403 --自定义的login_handler执行失败
simLogin.Err_Login_NotAcceptable = 406 --该用户已经在登陆中(只发生在 multilogin 关闭时)
simLogin.Err_Login_NotExistServer = 501 --网关不存在
simLogin.Err_Login_BeSealed = 502 --账号处于封号状态

-- 客户端版本号
local Version = "0.0.1"

-- 连接状态定义
local S2C_CHALLENGE = "S2C_CHALLENGE" --S->C:base64(8 bytes random challenge)
local S2C_SERVERKEY = "S2C_SERVERKEY" --S->C:base64(DH-Exchange(server key))
local S2C_HANDSHAKE = "S2C_HANDSHAKE" --S->C:握手的结果
local S2C_AUTH_TOKEN = "S2C_AUTH_TOKEN" --S->C:token认证结果

-- 构造
function simLogin:ctor()
	simLogin.super.ctor(self, "simLogin")

	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

	self.token = nil
	self.state = S2C_CHALLENGE

	self.last = ""		--socket数据

	self.challenge = nil
	self.clientkey = nil
	self.secret = nil
	self.kid = nil
	self.uid = nil
	self.subid = nil
    self.nodeid = nil
    self.ip = nil
    self.port = nil
end

-- 连接登录服
function simLogin:connectLogin(host, port, token)
	print("simLogin:connectLogin", host, port, token.user)
	self.token = token
	self.state = S2C_CHALLENGE
	self:connect(host, port)
end

function simLogin:S2C_CHALLENGE(msg)
    self.challenge = crypt.base64decode(msg)
	self.clientkey = crypt.randomkey()
    local b64clientkey = crypt.base64encode(crypt.dhexchange(self.clientkey))
	self.state = S2C_SERVERKEY
	print("simLogin:S2C_CHALLENGE ok, state=", self.state, "clientkey=", self.clientkey)
	self:sendMsg(b64clientkey)
end

function simLogin:S2C_SERVERKEY(msg)
    self.secret = crypt.dhsecret(crypt.base64decode(msg),self.clientkey)
	local hmac = crypt.hmac64(self.challenge,self.secret)
	local b64encodehmac = crypt.base64encode(hmac)
	self.state = S2C_HANDSHAKE
	print("simLogin:S2C_SERVERKEY ok, state=", self.state, "hmac=", hmac, "b64encodehmac=", b64encodehmac)
	self:sendMsg(b64encodehmac)
end

function simLogin:S2C_HANDSHAKE(msg)
    local code = tonumber(string.sub(msg, 1, 3))
	if code == simLogin.Err_Login_HandshakeFailed then
		--握手失败 登录失败
		print("simLogin:S2C_HANDSHAKE fail, code=", code)
		self:onFailure(code)
	else
        local etoken = crypt.desencode(self.secret, self:encodeToken(self.token))
        local b64encodetoken = crypt.base64encode(etoken)
        --print("=====simLogin sendMsg b64encodetoken=", b64encodetoken)
        self.state = S2C_AUTH_TOKEN
        --客户端版本号、平台、型号
        local b64encodeversion = crypt.base64encode(crypt.desencode(self.secret, Version))
        local model,systemPlatform,systemVersion,deviceId = "macosx", "mac", "macosx", "testdevice" --SoraDGetDeviceInfo()
        systemPlatform = tostring(systemPlatform) or "NONE"
        systemVersion = tostring(systemVersion) or "NONE"
        deviceId = tostring(deviceId) or "NONE"
        local language = "zh-CN"
		local ip = "127.0.0.1"
        local plateform = systemPlatform .. " " .. systemVersion .. " " .. deviceId .. " " .. ip .. " " .. language .. " "
        local b64encodeplateform = crypt.base64encode(crypt.desencode(self.secret,(plateform or "NONE")))
        local b64encodemodel = crypt.base64encode(crypt.desencode(self.secret,(model or "NONE")))
        local sendmsg = string.format("%s@%s@%s@%s",b64encodetoken,b64encodeversion,b64encodeplateform,b64encodemodel)
		print("simLogin:S2C_HANDSHAKE ok, state=", self.state, "sendmsg=", sendmsg)
		self:sendMsg(sendmsg)
	end
end

function simLogin:S2C_AUTH_TOKEN(msg)
	local code = tonumber(string.sub(msg, 1, 3))
	local submsg = string.sub(msg, 5)
	if code == simLogin.Err_Login_AuthTokenSuccess then
		--登录成功
		local resultmsg = crypt.base64decode(submsg)
        local b64kid,b64nodeid,b64ip,b64port,b64subid,b64uid,b64isInit = resultmsg:match("([^@]+)@([^@]+)@([^@]+)@([^@]+)@([^@]+)@([^@]+)@(.+)")

		--记录数据
        self.kid = crypt.base64decode(b64kid)
        self.nodeid = crypt.base64decode(b64nodeid)
        self.ip = crypt.base64decode(b64ip)
        self.port = crypt.base64decode(b64port)
		self.subid = crypt.base64decode(b64subid)
		self.uid = crypt.base64decode(b64uid)
		self.isInit = crypt.base64decode(b64isInit)
		print("simLogin:S2C_AUTH_TOKEN ok, kid=", self.kid, "nodeid=", self.nodeid, "ip=", self.ip, "port=", self.port, "uid=", self.uid, "subid=", self.subid, "isInit=", self.isInit)

		--通知token认证ok, 连接登陆服务器成功, 下面要开始连接网关
        self:connectLoginSuccess()
	else
		--登陆失败
		print("simLogin:S2C_AUTH_TOKEN fail, code=", code, submsg)
        self:onFailure(code)
	end
end

-- 连接登陆服务器成功
function simLogin:connectLoginSuccess()
	--print("simLogin:connectLoginSuccess", self.token.user)
	self:close()
	self:dispatchEvent({name = simLogin.Login_Success})
end

-- @override 连接登陆服务器失败
function simLogin:onFailure(code)
	print("simLogin:onFailure user=", self.token.user, "code=", code)
	self:close()
end

-- 按换行符解包
function simLogin:unpackLine(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

-- @override 处理消息
function simLogin:handleMsg(r)
	local left = r
	if self.last then
		left = self.last..r
	end
	while true do
		local msg
		msg, left = self:unpackLine(left)
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

-- 处理消息
function simLogin:dispatchMsg(msg)
	if self.state == S2C_CHALLENGE then
		self:S2C_CHALLENGE(msg)
	elseif self.state == S2C_SERVERKEY then
		self:S2C_SERVERKEY(msg)
	elseif self.state == S2C_HANDSHAKE then
		self:S2C_HANDSHAKE(msg)
	elseif self.state == S2C_AUTH_TOKEN then
		self:S2C_AUTH_TOKEN(msg)
	end
end

-- 发送数据
function simLogin:sendMsg(text)
	self:send(text.."\n")
end

-- token加密处理
function simLogin:encodeToken(token)
	return string.format("%s@%s:%s", crypt.base64encode(token.user), crypt.base64encode(token.pass), crypt.base64encode(token.subtoken))
end

return simLogin