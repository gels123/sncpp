--[[
    gm指令模块
]]
local skynet = require("skynet")
local svrAddrMgr = require("svrAddrMgr")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local gmCtrl = class("gmCtrl")

-- gm添加单个物品 reqGmCmd text='/addItem 1 10'
function gmCtrl:addItem(params)
    local id = tonumber(params[1])
    local count = tonumber(params[2])
    if not id or id <= 0 or not count or count <= 0 then
        gLog.d("gmCtrl:addItem error", player:getUid(), id, count)
        return false
    end
    gLog.i("gmCtrl:addItem do", player:getUid(), id, count)
    local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    return backpackCtrl:addItem(id, count)
end

-- gm使用一种物品 reqGmCmd text='/useItem 1001 10'
function gmCtrl:useItem(params)
    local id = tonumber(params[1])
    local count = tonumber(params[2])
    if not id or id <= 0 or not count or count <= 0 then
        gLog.d("gmCtrl:useItem error", player:getUid(), id, count)
        return false
    end
    gLog.i("gmCtrl:useItem do", player:getUid(), id, count)
    local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    return backpackCtrl:useItem(id, count)
end

-- gm清空背包 reqGmCmd text='/clearBackpack'
function gmCtrl:clearBackpack(params)
    gLog.i("gmCtrl:clearBackpack do", player:getUid())
    local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    return backpackCtrl:clearBackpack()
end

-- gm暂离 reqGmCmd text='/afk'
function gmCtrl:afk(params)
    gLog.i("gmCtrl:afk do", player:getUid())
    local gateSvr = svrAddrMgr.getSvr(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
    skynet.send(gateSvr, "lua", "afk", player:getUid(), player:getSubid(), 2) --2=请求afk
    return true
end

--发送测试邮件 reqGmCmd text='/sendMail'
function gmCtrl:sendMail(params)
    local cfgid = tonumber(params[1]) or 1
    local content = {
        brief = {1, "name1"},
        more = {
            array={"itemId(@)41"},
            ranklist = {},
        },
        extra = {
            items={{id=1001,count=1}, {itemId=1002,count=10}},
        }
    }
    require("mailLib"):sendMail(player:getKid(), 0, {player:getUid()}, cfgid, content)
end


return gmCtrl
