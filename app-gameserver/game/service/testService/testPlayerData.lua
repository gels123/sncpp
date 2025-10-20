-------testPlayerDataCenter.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")
local zset = require("zset")

xpcall(function()	
gLog.i("=====testPlayerDataCenter begin")
print("=====testPlayerDataCenter begin")
	
	local redisLib = require("redisLib")
	local json = require("json")
	local playerDataLib = require("playerDataLib")
	local playerDataCenter = include("playerDataCenter"):shareInstance()

    playerDataLib:sendUpdate(1, 1201, "lordinfo", {uid = 1201, name = "11111a"})
    playerDataLib:sendUpdate(1, 1201, "lordinfo", {uid = 1201, name = "22222a"})
    playerDataLib:update(1, 1201, "lordinfo", {uid = 1201, name = "3333a"})
    playerDataLib:sendDelete(1, 1201, "lordinfo")
    local ret = playerDataLib:query(1, 1201, "lordinfo")
    gLog.dump(ret, "23432=4=3==", 10)
    playerDataLib:sendDelete(1, 1201, "lordinfo")
    playerDataLib:update(1, 1201, "lordinfo", {uid = 1201, name = "99999a"})
    local ret = playerDataLib:query(1, 1201, "lordinfo")
    gLog.dump(ret, "23432=4=6==", 10)


gLog.i("=====testPlayerDataCenter end")
print("=====testPlayerDataCenter end")
end,svrFunc.exception)