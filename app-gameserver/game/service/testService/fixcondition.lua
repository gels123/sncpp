-------fixcondition.lua
-------
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")

xpcall(function()
	--gLog.i("=====fixcondition begin")
	print("=====fixcondition begin")

	-- local eventLib = require("eventLib")
	-- eventLib:dispatchEvent(200001, 0, {aName = "xxx"})

	local conditionMgr = require("conditionMgr")
	local agentCenter = require("agentCenter"):shareInstance()
	local player = agentCenter:getPlayer()
	local conditions = {
		[1] = {
			["compare"] = {
				["compareType"] = 0,
				["data"] = {
					[1] = 0
				}
			},
			["type"] = {
				["conditionType"] = 101,
				["data"] = {
					[1] = 300222
				}
			}
		}
	}
	local h = conditionMgr.register(player, conditions, function (isMeet, handle)
		gLog.i("=============", isMeet, handle)
	end)

	player:dispatchEvent(gEventDef.Event_UidLogin)

	gLog.i("=====fixcondition end")
	print("=====fixcondition end")
end,svrFunc.exception)