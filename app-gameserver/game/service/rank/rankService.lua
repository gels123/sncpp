--[[
    排行榜服务
--]]
require("quickframework.init")
require("cluster")
require("svrFunc")
require("errDef")
local skynet = require "skynet"
local profile = require "skynet.profile"
local svrAddrMgr = require "svrAddrMgr"
local rankCenter = require("rankCenter"):shareInstance()

local kid,idx = ...
kid,idx = tonumber(kid), tonumber(idx)
assert(kid and idx)
local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("rankCenter cmd enter => ", session, source, cmd, ...)
        profile.start()

        rankCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("rankCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.rankSvr, kid, idx)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, idx)
end)