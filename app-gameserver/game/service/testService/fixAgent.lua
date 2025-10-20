--[[
	玩家Agent服热更注
	用法：
		log fixAgent fixAgentDemo
]]
require "quickframework.init"
local skynet = require "skynet"
local sharedataLib = require "sharedataLib"
local dbconf = require "dbconf"
local svrFunc = require "svrFunc"
local svrConf = require "svrConf"
local svrAddrMgr = require "svrAddrMgr"

local script = ...
script = script or "fixAgentDemo"
--gLog.i("fixAgent script =", script)

local function fixAgent()
	-- 需要进行热更的服务器
	local kids = svrConf:getKingdomIDListByNodeID(dbconf.gamenodeid)

	-- 各个服务器开始进行热更
	gLog.i("fixAgent begin =", script, "kids=", table2string(kids))
	local count = 0
	for _, kid in pairs(kids) do
		skynet.fork(function()
			local agentPoolSvr = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, kid)
			local ok = skynet.call(agentPoolSvr, "lua", "hotFix", script)
			gLog.i("fixAgent do kid =", kid, "ok=", ok)
			count = count + 1
			if count >= #kids then
				gLog.i("fixAgent end =", script)
				skynet.fork(function()
					skynet.exit()
				end)
			end
		end)
	end
end

skynet.start(function()
	xpcall(fixAgent, svrFunc.exception)
end)