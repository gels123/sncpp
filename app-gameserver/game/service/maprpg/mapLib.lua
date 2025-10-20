--[[
	地图服务对外接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local mapLib = class("mapLib")

-- 服务数量
mapLib.serviceNum = 16

-- 获取服务地址
function mapLib:getAddress(kid, id)
	return svrAddrMgr.getSvr(svrAddrMgr.mapSvr, kid, id%mapLib.serviceNum + 1)
end

-- call调用
function mapLib:call(kid, id, ...)
	return skynet.call(self:getAddress(kid, id), "lua", ...)
end

-- send调用
function mapLib:send(kid, id, ...)
	skynet.send(self:getAddress(kid, id), "lua", ...)
end

return mapLib