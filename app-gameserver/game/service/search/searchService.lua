--[[
	寻路服务
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local profile = require "skynet.profile"
local searchCenter = require("searchCenter"):shareInstance()

local ti = {}

local kid, idx = ...
kid, idx = tonumber(kid), tonumber(idx)
assert(kid and idx)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- gLog.d("searchCenter cmd enter => ", session, source, cmd, ...)

        profile.start()

        xpcall(searchCenter.dispatchCmd, svrFunc.exception, searchCenter, session, source, cmd, ...)

        local time = profile.stop()
        if time > gOptTimeOut then
            gLog.w("searchCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 设置地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.searchSvr, kid, idx)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, idx)

    -- 通知启动服务，本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.searchSvr, kid, idx), skynet.self())
end)