--[[
    行军队列服务
]]
require "quickframework.init"
require("svrFunc")
require "sharedataLib"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local profile = require "skynet.profile"
local svrAddrMgr = require("svrAddrMgr")
local queueCenter = require("queueCenter"):shareInstance()

local kid = tonumber(...)
local ti = {}

assert(kid)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("queueCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        queueCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("queueCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.queueSvr, kid)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
    -- 通知启动服务，本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.queueSvr, kid), skynet.self())
end)
