local skynet = require("skynet")
local lfs = require("lfs")
local condType2Cls = {}

local nextHandle = 1
local handle2context = {}
local conditionMgr = {}
local inited, started = false, false
local gLog, gEvent2Channel, gEventTypeDef, string, assert, error, type, next, pairs, table = gLog, gEvent2Channel, gEventTypeDef, string, assert, error, type, next, pairs, table

function conditionMgr.init()
    if inited then
        return
    end
    inited = true
    local dir = lfs.currentdir()
    local c = string.sub(dir, string.len(dir), string.len(dir))
    if c == "/" or c == "\\" then
        dir = dir.."game/service/agent/module/cond/conditions"
    else
        dir = dir.."/game/service/agent/module/cond/conditions"
    end
    for filename_ in lfs.dir(dir) do
        local _, a = string.find(filename_, dir)
        local b = string.find(filename_, ".lua")
        if b then
            local file = string.sub(filename_, a and a+2 or 0, b-1)
            gLog.i("conditionMgr:init dir=", dir, "filename_=", filename_, "a=", a, "b=", b, "filename=", file)
            local cls = require(file)
            assert(cls, string.format("conditionMgr.init,load cls fail,path=%s", file))
            if type(cls.check) ~= "function" then
                error(string.format("conditionMgr.init error,condition.check function error"))
            end
            local conditionType = cls.conditionType
            assert(conditionType and not condType2Cls[conditionType], string.format("conditionMgr.init,exists,conditionType=", conditionType))
            assert(cls.triggerEvents and next(cls.triggerEvents), string.format("conditionMgr.init,triggerEvents error,conditionType=%s", conditionType))
            condType2Cls[conditionType] = cls
        end
    end
end

function conditionMgr.getConditionCls(conditionType)
    return condType2Cls[conditionType]
end

local function cbEvent(event, handle)
    -- gLog.debug("conditionMgr.cbEvent,handle=%s", handle)
    if not started then
        return
    end
    local context = handle2context[handle]
    if not context then
        gLog.warn("conditionMgr.cbEvent,not found,handle=%s", handle)
        return
    end
    local conditions = context.conditions
    local isMeet = conditionMgr.check(context.player, conditions, event)
    if isMeet ~= context.isMeet then
        context.isMeet = isMeet
        local cb = context.cb
        local cbobj = context.cbobj
        if cbobj then
            cb(cbobj, isMeet, handle)
        end
        if cbobj then
            if type(cb) == "function" then
                cb(cbobj, isMeet, handle)
            else
                cbobj[cb](cbobj, isMeet, handle)
            end
        else
            cb(isMeet, handle)
        end
    end
end

local function _register(player, triggerEvents, cb, cbobj, handle, tb)
    local listeners = {}
    for _, eventId in pairs(triggerEvents) do
        assert(gEvent2Channel[eventId] == gEventTypeDef.Player, string.format("[condition].register,eventId=%s", eventId))
        if not tb[eventId] then
            tb[eventId] = eventId
            local listener = player:registerEvent(eventId, cb, cbobj, handle)
            table.insert(listeners, listener)
        end
    end
    return listeners
end

function conditionMgr.register(player, conditions, cb, cbobj)
    assert(next(conditions) and (type(cb) == "function" or (type(cbobj and cbobj[cb]) == "function")), string.format("conditionMgr.register error!"))
    local handle = nextHandle
    nextHandle = nextHandle + 1
    local context = {
        handle = handle,
        player = player,
        conditions = conditions,
        cb = cb,
        cbobj = cbobj,
        listeners = {},
    }
    local tb = {}
    for k, condition in pairs(conditions) do
        local conditionType = condition.type.conditionType
        local cls = condType2Cls[conditionType]
        assert(cls, string.format("conditionMgr.register,conditionType(%s) not impl", conditionType))
        context.listeners[k] = _register(player, cls.triggerEvents, cbEvent, nil, handle, tb)
    end
    handle2context[handle] = context
    if started then
        skynet.fork(function()
            if handle2context[handle] then
                cbEvent(nil, handle)
            end
        end)
    end
    return handle
end

local function _unregister(player, listeners)
    for _, listener in pairs(listeners) do
        player:unregisterEvent(listener)
    end
end

function conditionMgr.unregister(handle)
    -- gLog.debug("conditionMgr.unregister,handle=%s", handle)
    local context = handle2context[handle]
    if context then
        local listeners = context.listeners
        local conditions = context.conditions
        for k, condition in pairs(conditions) do
            _unregister(context.player, listeners[k])
        end
        handle2context[handle] = nil
    end
end

function conditionMgr.check(player, conditions, event)
    local isMeet = true
    for _, condition in pairs(conditions) do
        local conditionType = condition.type.conditionType
        local cls = condType2Cls[conditionType]
        if not cls.check(player, condition.type, condition.compare, event) then
            isMeet = false
            break
        end
    end
    return isMeet
end

function conditionMgr.start()
    if started then
        return
    end
    started = true
    local handles = {}
    for handle, _ in pairs(handle2context) do
        table.insert(handles, handle)
    end
    for _, handle in pairs(handles) do
        if handle2context[handle] then
            cbEvent(nil, handle)
        end
    end
end

conditionMgr.init()

return conditionMgr