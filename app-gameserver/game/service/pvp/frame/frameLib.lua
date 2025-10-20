--[[
    pvp帧同步服务
]]
require("moduleDef")
local skynet = require ("skynet")
local dbconf = require ("dbconf")
local svrAddrMgr = require ("svrAddrMgr")
local svrConf = require ("svrConf")
local initDBConf = require ("initDBConf")
local frameLib = class("frameLib")

frameLib.serviceNum = 8

-- 根据id返回服务id
function frameLib:idx(batId)
    return tonumber(batId)%frameLib.serviceNum + 1
end

-- 获取地址
function frameLib:getAddress(kid, batId)
    return svrAddrMgr.getSvr(svrAddrMgr.frameSvr, kid, self:idx(batId))
end

-- call调用
function frameLib:call(kid, batId, ...)
    return skynet.call(self:getAddress(kid, batId), "lua", ...)
end

-- send调用
function frameLib:send(kid, batId, ...)
    skynet.send(self:getAddress(kid, batId), "lua", ...)
end

-- 推送消息
-- @batId   战场ID
-- @uid     玩家ID, 不传则推送给同战场内的所有人
function frameLib:notifyMsg(batId, cmd, msg, uid)
    self:send(batId, "notifyMsg", batId, cmd, msg, uid)
end

return frameLib
