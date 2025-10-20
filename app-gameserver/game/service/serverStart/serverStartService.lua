--[[
	服务器启动服务(其它服务都应向本服务同步状态)
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require("cluster")
local skynet = require "skynet"
local profile = require "skynet.profile"
local lextra = require("lextra")
local serviceCenter = require("serverStartCenter"):shareInstance()

local ti = {}

local kid = tonumber(...)

assert(kid)

-- 注册协议, 接收来自于c/c++层消息
skynet.register_protocol {
    name = "txt",
    id = 0,
    unpack = lextra.cstr_unpack,
}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("serverStartCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        xpcall(serviceCenter.dispatchCmd, svrFunc.exception, serviceCenter, session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("serverStartCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    skynet.dispatch("txt", function(session, source, cmd, ...)
        gLog.i("serverStartCenter txt enter => ", session, source, cmd, ...)
        xpcall(serviceCenter.dispatchCmd, svrFunc.exception, serviceCenter, session, source, cmd, ...)
    end)

    -- 注册 info 函数，便于 debug 指令 INFO 查询。
    skynet.info_func(function()
        gLog.i("info ti=", table2string(ti, nil, 10))
        return ti
    end)
    --设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.startSvr, kid)
    --初始化
    skynet.call(skynet.self(), "lua", "init", kid)
end)