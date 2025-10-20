--[[
	协议服务对外接口
]]
local skynet = require("skynet")
local sprotoloader = require("sprotoloader")
local protoLib = class("protoLib")

-- [客户端用]客户端请求包序列化
function protoLib:c2sEncode(cmd, msg, session)
	if not self.s2cHost then
		self.s2cHost = sprotoloader.load(2):host("package")
	end
	if not self.c2sRequest then
		self.c2sRequest = self.s2cHost:attach(sprotoloader.load(1))
	end
    return self.c2sRequest(cmd, msg, session)
end

-- [服务端用]客户端请求包反序列化 返回: 请求类型("REQUEST" or "RESPONSE") 请求名 请求参数 回应函数
function protoLib:c2sDecode(msg, sz)
	if not self.c2sHost then
		self.c2sHost = sprotoloader.load(1):host("package")
	end
    return self.c2sHost:dispatch(msg, sz)
end

-- [服务端用]服务端请求包序列化
function protoLib:s2cEncode(cmd, msg, session)
	if not self.c2sHost then
		self.c2sHost = sprotoloader.load(1):host("package")
	end
	if not self.s2cRequest then
		self.s2cRequest = self.c2sHost:attach(sprotoloader.load(2))
	end
    return self.s2cRequest(cmd, msg, session)
end

-- [客户端用]服务端请求包反序列化 --返回: 请求类型("REQUEST" or "RESPONSE") 请求名 请求参数 回应函数
function protoLib:s2cDecode(msg)
	if not self.s2cHost then
		self.s2cHost = sprotoloader.load(2):host("package")
	end
    return self.s2cHost:dispatch(msg)
end

return protoLib