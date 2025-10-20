--[[
    开启调试
]]
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
    gLog.i("=====fixdebug begin")

    -- 开启调试监听, 等了ide连接
    package.cpath = package.cpath .. ';/Users/gels/Library/Application Support/JetBrains/CLion2022.3/plugins/EmmyLua/debugger/emmy/mac/arm64/?.dylib'
    local dbg = require "emmy_core"
    local port = 9966
    local ok = dbg.tcpListen('0.0.0.0', port)
    gLog.d("fixdebug start debugger success=", skynet.self(), "port=", port, "ok=", ok)

    ---- 服务器连接IDE
    --local dbg = require('emmy_core')
    --dbg.tcpConnect('1', 9967)


    gLog.i("=====fixdebug end")
end, svrFunc.exception)