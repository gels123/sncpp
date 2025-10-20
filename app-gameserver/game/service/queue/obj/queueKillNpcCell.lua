--[[
    打怪队列
]]
local skynet = require "skynet"
local queueCenter = require("queueCenter"):shareInstance()
local queueCell = require "queueCell"
local queueKillNpcCell = class("queueKillNpcCell", queueCell)

-- override
function queueKillNpcCell.get_db_fields()
    local db_fields = queueKillNpcCell.super.get_db_fields()
    table.merge(db_fields, {
    })
    return db_fields
end

-- override
function queueKillNpcCell:init(params, ...)
    self.super.init(self, params)
end

-- override
function queueKillNpcCell:onMoving()
    -- 锁定目标怪
    -- kingdomMapLib:sendUpdateMapObjPro(gKid, queue:getAttr("toId"), {mapType = self:getAttr("toMapType")}, {needRefresh = false,})
    return true
end

-- override
function queueKillNpcCell:onArrive()
    -- -- 发生战斗
    -- local errCode, battleResult = warCenterLib:opt(gKid, gWarType.npc, queueUtils:getCompatibleQueueData4Battle(queue), nil, queue:getUid(), npcId, {queueType = queueType})
    -- gLog.dump(battleResult, "attackLordUnit:onArrive battleResult", 9)
    -- if not battleResult or not next(battleResult) then
    --    -- 战斗失败
    --    gLog.w("attackLordUnit:onArrive warCenterLib:opt error errCode = ", errCode)
    --    return errCode
    -- end
    -- queue:setAttr("hasAttack", true)
    -- -- 结算双方队列兵力
    -- queueUtils:settleArmyChange(battleResult.attackerLoseArmy, {queue})
    -- local normalRewardItems, firstRewardItems
    -- if battleResult.isAttackWin then
        
    -- else
    --     -- 失败邮件
    --     self:sendAttackNPCMail(gWarResultType.lose, nil, nil, nil, battleResult.warReport.fightDetail)
    -- end
    queueCallbackLogic:returnQueue(self)
    return true
end

-- override
function queueKillNpcCell:onReturn()
    local queue = self:getQueue()
    if not queue:getAttr("hasAttack") then
        -- 异常返回的情况，需要返还体力以及发送邮件
        local playerProxy = queue:getPlayerProxy()
        playerProxy:updatePhysical(gLordValueDef.kill_consume_physical, false, true)
        self:sendAttackNPCMail(gWarResultType.invalid)
    end
end

return queueKillNpcCell