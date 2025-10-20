--
-- Author: SuYinXiang (sue602@163.com)
-- Date: 2016-11-04 17:46:13
--

--[[inject 方式修复
	fixReconnectRabbitmq.lua 00000066
	fixServiceByLogService
	logService,/home/rok/rok_server/kingdom-of-heaven-server/game/service/testService/fixReconnectRabbitmq6.lua
]]

local mgrLogDataMgr = include("mgrLogDataMgr").sharedInstance()
gLog.i("len -=",#mgrLogDataMgr.logDataQueue,mgrLogDataMgr.isRunning)
print("len -=",#mgrLogDataMgr.logDataQueue,mgrLogDataMgr.isRunning)


local skynet = require("skynet")
skynet.fork(function()
	local ok, err = mgrLogDataMgr.mqclient:retryconnect()
	print("fixReconnectRabbitmq result", ok, err)
	gLog.i("fixReconnectRabbitmq result", ok, err)
end)
gLog.i("fix reconnect success")
print("fix reconnect success")

