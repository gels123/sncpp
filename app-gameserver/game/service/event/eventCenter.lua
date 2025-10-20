--[[
    事件服务中心
]]
local skynet = require 'skynet'
local mc = require 'multicast'
local serviceCenterBase = require('serviceCenterBase2')
local eventCenter = class('eventCenter', serviceCenterBase)

local gEvent2Channel = gEvent2Channel
local stringformat = string.format

-- 构造
function eventCenter:ctor()
    eventCenter.super.ctor(self)
end

-- 初始化
function eventCenter:init(nodeid)
    gLog.i('eventCenter:init begin=', nodeid)

    -- 节点ID
    self.nodeid = nodeid
    -- 频道
    self.channels = {}
    -- 频道订阅源地址
    self.addrs = {}

    gLog.i('eventCenter:init end=', nodeid)
    return true
end

-- 注册事件
function eventCenter:registerEvent(eventId, objId, addr)
    assert(gEvent2Channel[eventId], stringformat('registerEvent invalid %s %s', eventId, objId))
    local id = stringformat(gEvent2Channel[eventId], objId)
    if not self.channels[id] then
        self.channels[id] = mc.new()
        self.addrs[id] = {}
        gLog.i('eventCenter:registerEvent=', id, self.channels[id].channel)
    end
    self.addrs[id][addr] = addr

    return self.channels[id].channel
end

-- 移除事件
function eventCenter:unregisterEvent(eventId, objId, addr)
    assert(gEvent2Channel[eventId], stringformat('unregisterEvent invalid %s %s', eventId, objId))
    local id = stringformat(gEvent2Channel[eventId], objId)
    if self.channels[id] then
        if addr then
            self.addrs[id][addr] = nil
        end
        if not next(self.addrs[id]) then
            gLog.i('eventCenter:unregisterEvent=', id, self.channels[id].channel)
            self.channels[id]:delete()
            self.channels[id] = nil
            self.addrs[id] = nil
        end
    end
    -- gLog.dump(self.channels, "eventCenter:unregisterEvent channels=")
    -- gLog.dump(self.addrs, "eventCenter:unregisterEvent addrs=")
end

-- 移除所有事件
function eventCenter:unregisterAllEvent()
    if next(self.channels) then
        for id, v in pairs(self.channels) do
            if v.channel then
                v:delete()
            end
        end
        self.channels = {}
        self.addrs = {}
    end
end

-- 广播事件
function eventCenter:dispatchEvent(eventId, objId, ...)
    assert(eventId and gEvent2Channel[eventId], stringformat('dispatchEvent invalid %s %s', eventId, objId))
    local id = stringformat(gEvent2Channel[eventId], objId)
    local channel = self.channels[id]
    if channel then
        -- gLog.d("eventCenter:dispatchEvent channel,event=", id, eventId, ...)
        channel:publish(eventId, objId, ...)
    else
        gLog.d("eventCenter:dispatchEvent ignore channel,event=", id, eventId, ...)
    end
end

return eventCenter
