-------fixevent.lua
-------
---
require("eventDef")
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")
local eventCtrl = require ("eventCtrl")
local eventLib = require ("eventLib")

xpcall(function()
	gLog.i("=====fixevent begin")
	print("=====fixevent begin")

	local cb1 = function(...)
		gLog.i("cb1=====100", ...)
	end
	local cb2 = function(...)
		gLog.i("cb2=====100", ...)
	end
	local cb3 = function(...)
		gLog.i("cb3=====200", ...)
	end
	local h1 = eventLib:registerEvent(gEventDef.Event_UidLogin, 100, cb1)
	local h2 = eventLib:registerEvent(gEventDef.Event_UidLogin, 100, cb2)
	local h3 = eventLib:registerEvent(gEventDef.Event_UidLogin, 200, cb3)
	local dispatchs, handlers = eventCtrl.get()
	local channels = eventLib:get()
	gLog.dump(dispatchs, "fixevent dispatchs 1=")
	gLog.dump(handlers, "fixevent handlers 1=")
	gLog.dump(channels, "fixevent channels 1=")

	----gLog.i("registerEvent1=====", h1)
	----local h3 = eventLib:registerEvent(1, 200, cb)
	----local h4 = eventLib:registerEvent(2, nil, cb)
	----gLog.i("registerEvent2=====", h2)
	--local dispatchs, handlers = eventCtrl.get()
	----
	--eventLib:unregisterEvent(h1)
	--eventLib:unregisterEvent(h2)
	--eventLib:unregisterEvent(h3)
	--local dispatchs, handlers = eventCtrl.get()
	--local channels = eventLib:get()
	--gLog.dump(dispatchs, "fixevent dispatchs 2=")
	--gLog.dump(handlers, "fixevent handlers 2=")
	--gLog.dump(channels, "fixevent channels 2=")
	--
	--eventLib:dispatchEvent(gEventDef.Event_UidLogin, 100, "data111", "data222")
	--eventLib:dispatchEvent(gEventDef.Event_UidLogin, 200, "data333", "data444")
	------eventLib:unregisterEvent(h1)
	----eventLib:dispatchEvent(1, 100, "data111", "data222")
	----eventLib:dispatchEvent(1, 200, "data333", "data444")

	gLog.i("=====fixevent end")
	print("=====fixevent end")
end,svrFunc.exception)