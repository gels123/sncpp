--[[
    邮件服务
--]]
require("logDef")
require("quickframework.init")
require("cluster")
require("svrFunc")
require("agentDef")
require("errDef")
local skynet = require "skynet"
local profile = require "skynet.profile"
local mailCenter = require("mailCenter"):shareInstance()

local kid,idx = ...
kid,idx = tonumber(kid), tonumber(idx)
local ti = {}

assert(kid)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("mailCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        mailCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("mailCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.mailSvr, kid, idx)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, idx)
    -- 通知启动服务，本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.mailSvr, kid, idx), skynet.self())
end)