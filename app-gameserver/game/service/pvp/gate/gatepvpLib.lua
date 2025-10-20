--[[
    pvp网关服务接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local gatepvpLib = class("gatepvpLib")

-- call
function gatepvpLib:call(kid, ...)
    return skynet.call(svrAddrMgr.getSvr(svrAddrMgr.gatepvpSvr, kid), "lua", ...)
end

-- send
function gatepvpLib:send(kid, ...)
    skynet.send(svrAddrMgr.getSvr(svrAddrMgr.gatepvpSvr, kid), "lua", ...)
end

return gatepvpLib
