--[[
	背包/道具模块指令
]]
local skynet = require "skynet"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

--#请求背包信息
function clientCmd.reqBackpackInfo(player, req)
    gLog.dump(req, "clientCmd.reqBackpackInfo uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local backpackCtrl = player:getModule(gModuleDef.backpackModule)
        ret.backpacks = backpackCtrl:getInitData()
    until true

    ret.code = code
    return ret
end

--#使用一种物品
function clientCmd.reqUseItem(player, req)
    gLog.dump(req, "clientCmd.reqUseItem uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        --
        if not req.id or req.id <= 0 or not req.count or req.count <= 0 then
            gLog.d("clientCmd.reqUseItem error", player:getUid(), req.id, req.count)
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        --
        local backpackCtrl = player:getModule(gModuleDef.backpackModule)
        local ok, extra = backpackCtrl:useItem(req.id, req.count)
        if not ok then
            gLog.w("clientCmd.reqUseItem error", player:getUid(), ok, extra)
            code = extra or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.id = req.id
        ret.count = req.count
        ret.extra = extra
    until true

    ret.code = code
    return ret
end

--#使用多种种物品
function clientCmd.reqUseItems(player, req)
    gLog.dump(req, "clientCmd.reqUseItems uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        --
        if not req.items or #req.items <= 0 then
            gLog.d("clientCmd.reqUseItems error", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        for _,item in ipairs(req.items) do
            if not item.id or item.id <= 0 or not item.count or item.count <= 0 then
                gLog.d("clientCmd.reqUseItems error", player:getUid())
                code = gErrDef.Err_ILLEGAL_PARAMS
                break
            end
        end
        --
        local backpackCtrl = player:getModule(gModuleDef.backpackModule)
        local ok, extra = backpackCtrl:useItems(req.items)
        if not ok then
            gLog.w("clientCmd.reqUseItems error", player:getUid(), ok, extra)
            code = extra or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.extra = extra
    until true

    ret.code = code
    return ret
end

--#丢弃物品
function clientCmd.reqDeductItem(player, req)
    gLog.dump(req, "clientCmd.reqDeductItem uid="..tostring(player:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        --
        if not req.id or req.id <= 0 or not req.count or req.count <= 0 then
            gLog.d("clientCmd.reqDeductItem error", player:getUid(), req.id, req.count)
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        --
        local backpackCtrl = player:getModule(gModuleDef.backpackModule)
        local ok, err = backpackCtrl:deductItem(req.id, req.count)
        if not ok then
            gLog.w("clientCmd.reqDeductItem error", player:getUid(), ok, err)
            code = err or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.id = req.id
        ret.count = req.count
    until true

    ret.code = code
    return ret
end

return clientCmd
