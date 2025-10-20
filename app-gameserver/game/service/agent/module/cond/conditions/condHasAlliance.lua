--[[
    是否拥有联盟
]]
local condition = {conditionType = gConditionTypeDef.condHasAlliance}
condition.triggerEvents = {gEventDef.Event_UidLogin}

function condition.check(player, type, compare, event)
    local lordCtrl = player:getModule(gModuleDef.lordModule)
    local aid = lordCtrl:getAid()
    return aid > 0
end

return condition