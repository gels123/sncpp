--[[
	服务器启动服务接口
]]
local skynet = require ("skynet")
local serverStartLib = class("serverStartLib")

-- 获取服务地址
function serverStartLib:getAddress(kid)
	return svrAddrMgr.getSvr(svrAddrMgr.startSvr, kid)
end

-- call调用
function serverStartLib:call(kid, ...)
	return skynet.call(self:getAddress(kid), "lua", ...)
end

-- send调用
function serverStartLib:send(kid, ...)
	skynet.send(self:getAddress(kid), "lua", ...)
end

-- 获取频道
function serverStartLib:getChannel(kid)
	return self:call(kid, "getChannel")
end

-- 获取是否所有服均已初始化好
function serverStartLib:getIsOk(kid)
	return self:call(kid, "getIsOk")
end

-- 完成初始化
function serverStartLib:finishInit(kid, svrName, address)
	self:send(kid, "finishInit", svrName, address)
end

-- 停止所有服务
function serverStartLib:stop(kid)
	self:send(kid, "stop")
end

-- 业务ID映射全局服节点
function serverStartLib:hashNodeidGb(kid, id)
	return self:call(kid, "hashNodeidGb", id)
end

return serverStartLib
