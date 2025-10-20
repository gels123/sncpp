--[[
	行军队列服务对外接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local queueLib = class("queueLib")

-- 获取服务地址
function queueLib:getAddress(kid)
	return svrAddrMgr.getSvr(svrAddrMgr.queueSvr, kid)
end

-- call调用
function queueLib:call(kid, ...)
	return skynet.call(self:getAddress(kid), "lua", ...)
end

-- send调用
function queueLib:send(kid, ...)
	skynet.send(self:getAddress(kid), "lua", ...)
end

return queueLib