local skynet = require("skynet")
local sprotoloader = require("sprotoloader")
local sprotoLib = class("sprotoLib")

-- [客户端用]客户端请求包编码
function sprotoLib:csEncodeReq(name, data, session)
	if not self.scHost then
		self.scHost = sprotoloader.load(2):host("package")
	end
	if not self.csRequest then
		self.csRequest = self.scHost:attach(sprotoloader.load(1))
	end
    return self.csRequest(name, data, session)
end

-- [服务端用]客户端请求包解码
function sprotoLib:csDecodeReq(data)
	if not self.csHost then
		self.csHost = sprotoloader.load(1):host("package")
	end
    return self.csHost:dispatch(data) --返回: 请求类型("REQUEST" or "RESPONSE") 请求名 请求参数 回应函数
end

-- [服务端用]服务端请求包编码
function sprotoLib:scEncodeReq(name, data, session)
	if not self.csHost then
		self.csHost = sprotoloader.load(1):host("package")
	end
	if not self.scRequest then
		self.scRequest = self.csHost:attach(sprotoloader.load(2))
	end
    return self.scRequest(name, data, session)
end

-- [客户端用]服务端请求包解码
function sprotoLib:scDecodeReq(data)
	if not self.scHost then
		self.scHost = sprotoloader.load(2):host("package")
	end
    return self.scHost:dispatch(data) --返回: 请求类型("REQUEST" or "RESPONSE") 请求名 请求参数 回应函数
end

return sprotoLib