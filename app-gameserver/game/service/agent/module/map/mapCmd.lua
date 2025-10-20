--[[
	地图模块指令
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

--#请求地图信息
function clientCmd.reqMapInfo(player, req)
    gLog.dump(req, "clientCmd.reqMapInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local mapCtrl = player:getModule(gModuleDef.mapModule)
        ret.mapInfo = mapCtrl:getInitData()
    until true

    ret.code = code
    return ret
end

return clientCmd
