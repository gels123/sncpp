--[[
	pvp战场网关服务
]]
require "quickframework.init"
require "configInclude"
require "svrFunc"
require "sharedataLib"
require "cluster"
require "errDef"
local skynet = require "skynet"
local profile = require "skynet.profile"
local gatepvpCenter = require("gatepvpCenter"):shareInstance()

local kid, mode = ...
kid, mode = tonumber(kid), tonumber(mode)
assert(kid and mode)
local ti = {}

-- 注册客户端指令
do
    require "frameCmd"
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        profile.start()

        gatepvpCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("gatepvpCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 注册 info 函数，便于 debug 指令 INFO 查询。
    skynet.info_func(function()
        gLog.i("info ti=", table2string(ti, nil, 10))
        return ti
    end)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, mode, 5000)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.gatepvpSvr, kid)
end)