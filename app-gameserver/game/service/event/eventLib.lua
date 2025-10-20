--[[
	跨服事件接口 (跨服事件使用eventLib，非跨服事件使用eventCtrl)
]]
require("eventDef")
local skynet = require ("skynet")
local skynetQueue = require ("skynet.queue")
local svrAddrMgr = require ("svrAddrMgr")
local eventCtrl = require ("eventCtrl")
local mc = require("skynet.multicast")
local eventLib = class("eventLib")

local type, string, assert, gEvent2Channel = type, string, assert, gEvent2Channel
local nodeid = assert(tonumber(skynet.getenv("nodeid")))
local sq = skynetQueue()
local channels = {}

-- for debug
function eventLib:get()
	return channels
end

-- 获取服务地址
function eventLib:getAddress(nodeid)
	return svrAddrMgr.getSvr(svrAddrMgr.eventSvr, nodeid)
end

-- call调用
function eventLib:call(nodeid, ...)
	return skynet.call(self:getAddress(nodeid), "lua", ...)
end

-- send调用
function eventLib:send(nodeid, ...)
	skynet.send(self:getAddress(nodeid), "lua", ...)
end

-- 添加事件监听(最好cb传函数名称，以方便热更)
function eventLib:registerEvent(eventId, objId, cb, cbobj, params)
	assert(eventId and gEvent2Channel[eventId] and (type(cb) == "function" or (type(cbobj and cbobj[cb]) == "function")), string.format("registerEvent error: %s %s", eventId, type(cb)))
	local id = string.format(gEvent2Channel[eventId], objId)
	if not channels[id] then
		sq(function()
			if channels[id] then
				return
			end
			local c = self:call(nodeid, "registerEvent", eventId, objId, skynet.self())
			assert(c, "registerEvent error: registerEvent invalid.")
			channels[id] = mc.new({
				channel = c,
				dispatch = function (_, _, ...)
					eventCtrl.dispatchEvent(...)
				end
			})
			channels[id]:subscribe()
		end)
	end
	local h = eventCtrl.registerEvent(eventId, objId, cb, cbobj, params)
	return h
end

-- 移除事件监听
function eventLib:unregisterEvent(h)
	local eventId, objId = eventCtrl.unregisterEvent(h)
	if eventId then
		local id = string.format(gEvent2Channel[eventId], objId)
		if channels[id] then
			channels[id]:unsubscribe()
			channels[id] = nil
		end
		self:send(nodeid, "unregisterEvent", eventId, objId, skynet.self())
	end
end

-- 广播事件
function eventLib:dispatchEvent(eventId, objId, ...)
	self:send(nodeid, "dispatchEvent", eventId, objId, ...)
end

-- 广播跨服事件
function eventLib:dispatchEventByNodeId(nodeid, eventId, objId, ...)
	self:send(nodeid, "dispatchEvent", eventId, objId, ...)
end

return eventLib
