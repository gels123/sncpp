--[[
	buff模块指令
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

--#请求buff信息
function clientCmd.reqBuffInfo(player, req)
    gLog.dump(req, "clientCmd.reqBuffInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local buffCtrl = player:getModule(gModuleDef.buffModule)
        ret.buffs = buffCtrl:getInitData()
    until true

    ret.code = code
    return ret
end

return clientCmd
