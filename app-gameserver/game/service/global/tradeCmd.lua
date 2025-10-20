--[[
	拍卖行模块指令
]]
local skynet = require "skynet"
local playerDataLib = require "playerDataLib"
local agentLibGb = require "agentLibGb"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

-- 查询自己的拍卖物 reqGoodsInfo
function clientCmd.reqGoodsInfo(player, req)
    gLog.dump(req, "clientCmd.reqGoodsInfo uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqGoodsInfo", req = req})
end

-- 添加拍卖物 reqAddGoods id=2 count=1 gold=50
function clientCmd.reqAddGoods(player, req)
    gLog.dump(req, "clientCmd.reqAddGoods uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqAddGoods", req = req})
end

-- 撤回拍卖物 reqRemGoods idx="478322673766469"
function clientCmd.reqRemGoods(player, req)
    gLog.dump(req, "clientCmd.reqRemGoods uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqRemGoods", req = req})
end

-- 购买拍卖物 reqBuyGoods sellUid=6761 type=0 idx="478351359578181" id=2 gold=50
function clientCmd.reqBuyGoods(player, req)
    gLog.dump(req, "clientCmd.reqBuyGoods uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqBuyGoods", req = req})
end

-- 查询拍卖物
function clientCmd.reqQueryGoods(player, req)
    gLog.dump(req, "clientCmd.reqQueryGoods uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqQueryGoods", req = req})
end

return clientCmd
