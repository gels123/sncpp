--[[
	聊天模块指令(转发到global服处理)
]]
local skynet = require "skynet"
local agentLibGb = require "agentLibGb"
local clientCmd = require "clientCmd"

-- 请求聊天/好友信息 reqChatInfo
function clientCmd.reqChatInfo(player, req)
    gLog.dump(req, "clientCmd.reqChatInfo uid="..tostring(player:getUid()))
    req.uid = player:getUid()
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqChatInfo", req = req})
end

-- 请求添加好友 reqApply uid=6753
function clientCmd.reqApply(player, req)
    gLog.dump(req, "clientCmd.reqApply uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqApply", req = req})
end

-- 回应添加好友 reqRspApply uid=6752 flag=true
function clientCmd.reqRspApply(player, req)
    gLog.dump(req, "clientCmd.reqRspApply uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqRspApply", req = req})
end

-- 请求添加/删除黑名单 reqSetBlacks uid=1001 flag=false
function clientCmd.reqSetBlacks(player, req)
    gLog.dump(req, "clientCmd.reqSetBlacks uid="..tostring(player:getUid()))
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqSetBlacks", req = req})
end

-- 请求发送聊天消息 reqChat uid=6753 msg={uid=0, tp=1,txt="leiho"}
function clientCmd.reqChat(player, req)
    gLog.dump(req, "clientCmd.reqChat uid="..tostring(player:getUid()))
    req.msg.uid = player:getUid()
    return agentLibGb:call(player:getKid(), player:getUid(), "dispatchGameMsg", player:getUid(), {cmd = "reqChat", req = req})
end

return clientCmd
