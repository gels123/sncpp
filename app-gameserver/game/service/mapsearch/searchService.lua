--[[
	寻路服务
]]
require "quickinit"
require "serviceFunctions"
require "sharedataLib"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local profile = require "skynet.profile"
local searchCenter = require("searchCenter"):shareInstance()

local ti = {}

local serverid, idx = ...
serverid, idx = tonumber(serverid), tonumber(idx)
assert(serverid and idx)

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        -- gLog.d("searchCenter cmd enter => ", session, source, cmd, ...)

        profile.start()

        xpcall(searchCenter.dispatchcmd, serviceFunctions.exception, searchCenter, session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("searchCenter:dispatchcmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 注册 info 函数，便于 debug 指令 INFO 查询。
    skynet.info_func(function()
        gLog.i("info ti=", table2string(ti))
        return ti
    end)

    -- 设置地址
    svrAddressMgr.setSvr(skynet.self(), svrAddressMgr.searchSvr, serverid, idx)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", serverid, idx)
end)