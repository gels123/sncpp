--[[
	协议服务
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require("cluster")
local skynet = require "skynet"
local profile = require "skynet.profile"
local protoCenter = include("protoCenter"):shareInstance()

local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- gLog.d("protoCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        xpcall(protoCenter.dispatchCmd, svrFunc.exception, protoCenter, session, source, cmd, ...)

        local time = profile.stop()
        if time > gOptTimeOut then
            gLog.w("protoCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    --设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.sprotoSvr)
    --初始化
    skynet.call(skynet.self(), "lua", "init")
end)