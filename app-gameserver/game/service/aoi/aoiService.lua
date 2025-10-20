--[[
    aoi视野服务
--]]
require "quickframework.init"
require "svrFunc"
require "sharedataLib"
require "errDef"
require "mapDef"
local skynet = require("skynet")
local svrAddrMgr = require("svrAddrMgr")
local profile = require("skynet.profile")
local lextra = require("lextra")
local aoiCenter = require("aoiCenter"):shareInstance()

local kid = tonumber(...)
assert(kid)

-- 接收来自于c/c++层消息
skynet.register_protocol {
    name = "txt",
    id = 0,
    unpack = lextra.cstr_unpack,
}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        profile.start()

        --gLog.d("aoiCenter:dispatchCmd", session, source, cmd, ...)
        aoiCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("aoiCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
        end
    end)
    skynet.dispatch("txt", function(session, source, cmd, ...)
        gLog.d("aoiCenter txt=", session, source, cmd, ...)
    end)
    -- 设置地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.aoiSvr, kid)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
    -- 通知启动服务，本服务已经初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.aoiSvr, kid), skynet.self())
end)
