-------fixtestredis.lua 测试共享redis性能
-------
local skynet = require ("skynet")
local cluster = require ("cluster")
local multiProc = require("multiProc")
local playerDataLib = require("playerDataLib")

xpcall(function()
	gLog.i("=====fixtestredis begin")
	print("=====fixtestredis begin")

	local kid = nil
	local time1 = skynet.time()
	local mp = multiProc.new()
	for i=1,10000,1 do
		mp:fork(function()
			kid = playerDataLib:getKidOfUid(1, 6382, true)
		end)
	end
	mp:wait()
	local time2 = skynet.time()
	gLog.i("fixtestredis end, costtime=", time2-time1)

	gLog.i("=====fixtestredis end")
	print("=====fixtestredis end")
end,svrFunc.exception)