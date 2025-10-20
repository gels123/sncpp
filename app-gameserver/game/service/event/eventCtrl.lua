--[[
	非跨服事件注册与分发接口 (跨服事件使用eventLib，非跨服事件使用eventCtrl)
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local eventCtrl = {}

local dispatchs = {}
local handlers, h = {}, 0

-- 注册事件
function eventCtrl.registerEvent(eventId, objId, cb, cbobj, params, async)
    assert(eventId and (type(cb) == "function" or (type(cbobj and cbobj[cb]) == "function")), string.format("eventCtrl.registerEvent error! %s %s", eventId, type(cb)))
    if not dispatchs[eventId] then
        dispatchs[eventId] = {[1] = {}, [2] = {}}
    end
    h = h + 1
    if objId then
        assert(not next(dispatchs[eventId][2]), string.format("eventCtrl.registerEvent had objId=nil type! %s %s %s", eventId, objId, cb))
        if not dispatchs[eventId][1][objId] then
            dispatchs[eventId][1][objId] = {}
        end
        dispatchs[eventId][1][objId][h] = {
            h = h,
            eventId = eventId,
            objId = objId,
            cb = cb,
            cbobj = cbobj,
            params = params,
            async = async,
        }
        handlers[h] = dispatchs[eventId][1][objId][h]
    else
        assert(not next(dispatchs[eventId][1]), string.format("eventCtrl.registerEvent had objId!=nil type! %s %s %s", eventId, objId, cb))
        dispatchs[eventId][2][h] = {
            h = h,
            eventId = eventId,
            cb = cb,
            cbobj = cbobj,
            params = params,
            async = async,
        }
        handlers[h] = dispatchs[eventId][2][h]
    end
    return h
end

-- 移除事件
function eventCtrl.unregisterEvent(h)
    assert(h, string.format("eventCtrl.unregisterEvent error! %s", h))
    if handlers[h] then
        local eventId, objId = handlers[h].eventId, handlers[h].objId
        if objId then
            dispatchs[eventId][1][objId][h] = nil
            if not next(dispatchs[eventId][1][objId]) then
                dispatchs[eventId][1][objId] = nil
            end
            if not next(dispatchs[eventId][1]) and not next(dispatchs[eventId][2]) then
                dispatchs[eventId] = nil
            end
            handlers[h] = nil
            if not dispatchs[eventId] or not dispatchs[eventId][1][objId] then
                return eventId, objId
            end
        else
            dispatchs[eventId][2][h] = nil
            if not next(dispatchs[eventId][1]) and not next(dispatchs[eventId][2]) then
                dispatchs[eventId] = nil
            end
            handlers[h] = nil
            if not dispatchs[eventId] then
                return eventId
            end
        end
    end
end

-- 分发事件
function eventCtrl.dispatchEvent(eventId, objId, event)
    assert(eventId, string.format("eventCtrl.dispatchEvent error! %s %s", eventId, objId))
    if objId then
        local tab = dispatchs[eventId] and dispatchs[eventId][1][objId]
        if next(tab) then
            local cb
            for h,v in pairs(tab) do
                if v.async then -- 异步协程处理
                    skynet.fork(function(...)
                        cb = v.cb
                        if v.cbobj then
                            if type(cb) == "function" then
                                cb(v.cbobj, ...)
                            else
                                v.cbobj[cb](v.cbobj, ...)
                            end
                        else
                            cb(...)
                        end
                    end, event, v.params)
                else -- 同步处理
                    xpcall(function(...)
                        cb = v.cb
                        if v.cbobj then
                            if type(cb) == "function" then
                                cb(v.cbobj, ...)
                            else
                                v.cbobj[cb](v.cbobj, ...)
                            end
                        else
                            cb(...)
                        end
                    end, debug.traceback, event, v.params)
                end
            end
        end
    else
        local tab = dispatchs[eventId][2]
        if next(tab) then
            local cb
            for h,v in pairs(tab) do
                xpcall(function(...)
                    cb = v.cb
                    if v.cbobj then
                        if type(cb) == "function" then
                            cb(v.cbobj, ...)
                        else
                            v.cbobj[cb](v.cbobj, ...)
                        end
                    else
                        cb(...)
                    end
                end, debug.traceback, event, v.params)
            end
        end
    end
end

function eventCtrl.get()
    return dispatchs, handlers
end

-- 移除所有事件
function eventCtrl.removeAll()
    dispatchs = {}
    handlers = {}
end

function eventCtrl.dump()
    gLog.dump(dispatchs, "eventCtrl.dispatchs")
    gLog.dump(handlers, "eventCtrl.handlers")
end

return eventCtrl