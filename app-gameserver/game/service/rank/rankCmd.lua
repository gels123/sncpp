--[[
	邮件指令
]]
local skynet =  require "skynet"
local rankConf = require "rankConf"
local rankLib = require "rankLib"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

-- 请求邮件封面数据
function clientCmd.reqRanklist(player, req)
    gLog.dump(req, "clientCmd.reqRanklist uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        --local covers = rankLib:call(player:getKid(), "reqCovers", player:getUid())
        --if not covers then
        --    code = gErrDef.Err_SERVICE_EXCEPTION
        --    break
        --end
        --ret.covers = covers
    until true

    ret.code = code
    return ret
end
