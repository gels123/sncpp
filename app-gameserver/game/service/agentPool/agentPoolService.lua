--[[
    玩家代理池服务
--]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require "cluster"
require "datacenter"
require "multicast"
require "agentDef"
local skynet = require "skynet"
local profile = require "skynet.profile"
local agentPoolCenter = require("agentPoolCenter"):shareInstance()

local ti = {}

local kid = tonumber(...)
assert(kid)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- gLog.d("agentPoolCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        agentPoolCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > gOptTimeOut then
            gLog.w("agentPoolCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    
    skynet.info_func(function()
        gLog.i("info ti=", table2string(ti))
        return ti
    end)

    -- 设置地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.agentPoolSvr, kid)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
    -- 通知启动服务，本服务已经初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.agentPoolSvr, kid), skynet.self())
end)
