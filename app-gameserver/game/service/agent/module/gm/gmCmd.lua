--[[
	gm指令模块
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"
local dbconf = require "dbconf"

--#请求使用gm指令
function clientCmd.reqGmCmd(player, req)
    gLog.dump(req, "clientCmd.reqGmCmd req=")
    if not (dbconf.DEBUG and dbconf.BACK_DOOR) then
        gLog.w("clientCmd.reqGmCmd fail1", player:getUid(), "text=", req.text)
        return {code = gErrDef.Err_NOT_DEBUG, msg = "not debug mode!"}
    end
    --
    local text = req.text or ""
    if string.sub(text,1,1) ~= "/" then
        gLog.w("clientCmd.reqGmCmd fail2", player:getUid(), "text=", req.text)
        return {code = gErrDef.Err_ILLEGAL_PARAMS, msg = "illegal params!"}
    end
    --
    local params = {}
    text = string.sub(text, 2)
    for w in string.gmatch(text, "%g+") do
        table.insert(params, w)
    end
    --
    local gmCtrl = require("gmCtrl")
    local f = gmCtrl[params[1]]
    if not f then
        gLog.w("clientCmd.reqGmCmd fail3", player:getUid(), "text=", req.text)
        return {code = gErrDef.Err_CMD_NOT_FOUND, msg = "cmd not found!"}
    end
    table.remove(params, 1)
    local ok, err = f(gmCtrl, params)
    if not ok then
        gLog.w("clientCmd.reqGmCmd fail4", player:getUid(), "text=", req.text)
        return {code = gErrDef.Err_SERVICE_EXCEPTION, msg = "service exception!"}
    end
    return {code = gErrDef.Err_OK, msg = "success"}
end
