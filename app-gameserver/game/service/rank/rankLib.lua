--[[
	邮件服务对外接口
]]
local skynet = require ("skynet")
local json = require "json"
local rankConf = require "rankConf"
local svrAddrMgr = require ("svrAddrMgr")
local agentLib = require ("agentLib")
local playerDataLib = require ("playerDataLib")
local rankLib = class("rankLib")

-- 服务数量
rankLib.serviceNum = 2

-- 获取服务地址
function rankLib:getAddress(kid, id)
	return svrAddrMgr.getSvr(svrAddrMgr.rankSvr, kid, id%rankLib.serviceNum + 1)
end

-- call调用
function rankLib:call(kid, id, ...)
	return skynet.call(self:getAddress(kid, id), "lua", ...)
end

-- send调用
function rankLib:send(kid, id, ...)
	skynet.send(self:getAddress(kid, id), "lua", ...)
end

return rankLib
