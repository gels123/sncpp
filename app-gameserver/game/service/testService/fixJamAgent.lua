--[[
	fixJamAgent.lua 
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local kid = player:getKingdomId()
local uid = player:getUid()
if not player.finishInit then
	gLog.i("player", uid, "not finishInit")
	skynet.sleep(1000)
	if not player.finishInit then
		gLog.i("start logout player")
		local playerAgentPoolSvrAdd = svrAddrMgr.getSvr(svrAddrMgr.agentPoolSvr, kid)
		skynet.send(playerAgentPoolSvrAdd, "lua", "logout", uid)
	else
		gLog.i("player", uid, "finishInit")
	end
end