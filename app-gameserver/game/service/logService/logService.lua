--[[
    日志打点服务
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require "cluster"
require "logDef"
local skynet = require "skynet"
local profile = require "skynet.profile"
local logCenter = require("logCenter"):shareInstance()

local kid = tonumber(...)
local ti = {}

assert(kid)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- gLog.d("logCenter cmd enter => ", session, source, cmd, ...)
        
        profile.start()

        logCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("logCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    --初始化
    skynet.call(skynet.self(), "lua", "init", kid)

    --设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.logSvr, kid)

    -- 通知启动服务, 本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.logSvr, kid), skynet.self())
end)