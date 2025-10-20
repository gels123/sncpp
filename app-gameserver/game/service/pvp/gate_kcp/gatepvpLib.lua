--[[
    pvp战场网关服务接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local gatepvpLib = class("gatepvpLib")

-- 获取地址
function gatepvpLib:getAddress(kid)
    return svrAddrMgr.getSvr(svrAddrMgr.gatepvpSvr, kid)
end

-- 推送消息给客户端 eg:  gatepvpCenter:send_msg(101, "reqClosePvpBattle", {batId=123})
-- @uid [必传]玩家ID
-- @name [必传]协议名称
-- @msg [必传]协议内容
function gatepvpLib:send_msg(kid, uid, name, msg)
    return skynet.call(self:getAddress(kid), "lua", "send_msg", uid, name, msg)
end

return gatepvpLib
