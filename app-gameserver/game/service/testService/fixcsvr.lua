-------fixcsvr.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
	gLog.i("=====fixcsvr begin")
	print("=====fixcsvr begin")

	local queueCenter = require("queueCenter"):shareInstance()
	local svr = skynet.launch("rudpsvr", 1234)
	queueCenter.svr = svr
	--local svr = skynet.call(".launcher", "lua" , "LAUNCH", "rudpsvr", "rudpsvrgate")

	skynet.send(queueCenter.svr, "lua", "clllsss", "aaa bbbb ccccc333")
	gLog.d("============svr=", queueCenter.svr)

	gLog.i("=====fixcsvr end")
	print("=====fixcsvr end")
end, svrFunc.exception)