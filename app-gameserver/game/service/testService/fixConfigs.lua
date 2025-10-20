---Hotfix all configs
---Usage: log fixServiceByLogService localData game/service/testService/fixConfigs.lua
---
local skynet = require ("skynet")
local cluster = require ("cluster")
local svrAddrMgr = require ("svrAddrMgr")

xpcall(function()
	print("=====fixConfigs begin")
	gLog.i("=====fixConfigs begin")

	local localDataLogic = require("localDataLogic")
	local ok = pcall(function()
		localDataLogic:init(true)
	end)
	if ok then
		gLog.i("fixConfigs reload configs success")
	else
		gLog.i("fixConfigs reload configs fail")
	end

	print("=====fixConfigs end")
	gLog.i("=====fixConfigs end")
end,svrFunc.exception)