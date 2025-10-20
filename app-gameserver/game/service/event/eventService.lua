--[[
    事件服务
--]]
require("quickframework.init")
require("cluster")
require("svrFunc")
require("errDef")
require("eventDef")
local skynet = require "skynet"
local profile = require "skynet.profile"
local svrAddrMgr = require "svrAddrMgr"
local eventCenter = require("eventCenter"):shareInstance()

local nodeid = tonumber(...)
assert(nodeid and nodeid > 0, "invalid nodeid")
local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("eventCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        eventCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("eventCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.eventSvr, nodeid)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", nodeid)
end)