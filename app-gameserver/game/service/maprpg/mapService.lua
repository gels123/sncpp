--[[
    地图服务
]]
require("logDef")
require("quickframework.init")
require("cluster")
require("svrFunc")
require("agentDef")
require("errDef")
local skynet = require ("skynet")
local profile = require ("skynet.profile")
local svrAddrMgr = require("svrAddrMgr")
local mapCenter = require("mapCenter"):shareInstance()

local kid, idx = ...
kid, idx = tonumber(kid), tonumber(idx)
assert(kid and kid > 0 and idx and idx > 0)
local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("mapCenter cmd enter => ", session, source, cmd, ...)
        profile.start()
        mapCenter:dispatchCmd(session, source, cmd, ...)
        local time = profile.stop()
        if time > 1 then
            gLog.w("mapCenter:dispatchcmd timeout time=", time, " cmd=", cmd)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, idx)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.mapSvr, kid, idx)
    -- 通知启动服务, 本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.mapSvr, kid, idx), skynet.self())
end)
