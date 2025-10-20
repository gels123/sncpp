--[[
	rpg模块指令
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

--#请求rpg信息
function clientCmd.reqRpgInfo(player, req)
    gLog.dump(req, "clientCmd.reqRpgInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local rpgCtrl = player:getModule(gModuleDef.rpgModule)
        ret.info = rpgCtrl:getInitData()
    until true

    ret.code = code
    return ret
end

--#请求进入地图
function clientCmd.reqRpgEnter(player, req)
    gLog.dump(req, "clientCmd.reqRpgEnter uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.tp or not req.move then
            gLog.d("clientCmd.reqRpgEnter err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local rpgCtrl = player:getModule(gModuleDef.rpgModule)
        local ok, mapid = rpgCtrl:enterMap(req.tp, req.move)
        if not ok then
            gLog.d("clientCmd.reqRpgEnter err2", player:getUid())
            code = mapid or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.tp = req.tp
        ret.move = req.move
        ret.mapid = mapid
    until true

    ret.code = code
    return ret
end

--#请求退出地图
function clientCmd.reqRpgExit(player, req)
    gLog.dump(req, "clientCmd.reqRpgExit uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local rpgCtrl = player:getModule(gModuleDef.rpgModule)
        rpgCtrl:exitMap()
    until true

    ret.code = code
    return ret
end

--#请求移动
function clientCmd.reqRpgMove(player, req)
    gLog.dump(req, "clientCmd.reqRpgMove uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.move then
            gLog.d("clientCmd.reqRpgMove err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local rpgCtrl = player:getModule(gModuleDef.rpgModule)
        local ok = rpgCtrl:move(req.move)
        if not ok then
            gLog.d("clientCmd.reqRpgMove err2", player:getUid())
            code = gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.move = req.move
    until true

    ret.code = code
    return ret
end

return clientCmd
