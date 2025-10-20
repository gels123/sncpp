--[[
    玩家代理服务
--]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require "multicast"
require "moduleDef"
require "eventDef"
require "errDef"
require "agentDef"
require "itemDef"
require "buffDef"
require "conditionDef"
local skynet = require("skynet")
local cluster = require("skynet.cluster")
local profile = require("skynet.profile")
local protoLib = require("protoLib")
local agentCenter = require("agentCenter"):shareInstance()

local kid = ...
kid = tonumber(kid)
assert(kid and kid > 0)

-- 注册客户端协议
skynet.register_protocol({
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        return protoLib:c2sDecode(msg, sz)
    end,
    dispatch = function(_, source, tp, cmd, req, rsp)
        --gLog.d("agent dispatch=", _, source, tp, cmd, args, rsp)
        if tp == "REQUEST" then
            agentCenter.player:dispatchMsg(cmd, req, rsp)
        else
            gLog.w("agent dispatch client error", agentCenter.player:getFd(), tp, cmd, req)
        end
    end,
})

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
        profile.start()

        --gLog.d("agentCenter:dispatchCmd", session, source, cmd, ...)
        agentCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > gOptTimeOut then
            gLog.w("agentCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
        end
	end)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
end)
