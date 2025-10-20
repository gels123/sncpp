--[[
	领主模块指令
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

--#请求领主信息
function clientCmd.reqLordInfo(player, req)
    gLog.dump(req, "clientCmd.reqLordInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local lordCtrl = player:getModule(gModuleDef.lordModule)
        ret.lordInfo = lordCtrl:getInitData()
        --player:notifyMsg("notifyLordInfo", {lordInfo = lordCtrl:getInitData(),})
    until true

    ret.code = code
    return ret
end

--#请求修改领主信息
function clientCmd.reqModifyLordInfo(player, req)
    gLog.dump(req, "clientCmd.reqModifyLordInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local lordCtrl = player:getModule(gModuleDef.lordModule)
        ret.lordInfo = lordCtrl:getInitData()
        --player:notifyMsg("notifyLordInfo", {lordInfo = lordCtrl:getInitData(),})
    until true

    ret.code = code
    return ret
end

--#请求创建角色
function clientCmd.reqCreateNpc(player, req)
    -- gLog.dump(req, "clientCmd.reqCreateNpc uid="..tostring(player:getUid()))
    -- local ret = {}
    -- local code = gErrDef.Err_OK

    -- repeat
    --     local lordCtrl = player:getModule(gModuleDef.lordModule)
    --     local ok, code2 = lordCtrl:reqCreateNpc(req.info)
    --     if not ok then
    --         gLog.d("clientCmd.reqCreateNpc error1", player:getUid())
    --         code = code2 or gErrDef.Err_SERVICE_EXCEPTION
    --         break
    --     end
    --     ret.info = code2
    -- until true

    -- ret.code = code
    -- return ret
end

return clientCmd
