-------fixmail.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()	
gLog.i("=====fixmail begin")
print("=====fixmail begin")


	local gateCenter = require("gateCenter"):shareInstance()


	
gLog.i("=====fixmail end")
print("=====fixmail end")
end,svrFunc.exception)