--[[
    道具使用相关逻辑
--]]
local skynet = require "skynet"
local backpackConf = require("backpackConf")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local backpackLogic = class("backpackLogic")

--->>>>>>>>>>>>>>>>>>>>>>>>>>>>> 使用道具校验 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 使用道具校验
function backpackLogic.useCheckNone(id, count, ...)
    return true
end

-- 使用礼包道具校验
function backpackLogic.useCheckRewardPack(id, count, ...)
    -- 等级判断
    return true
end
---<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 使用道具校验 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--->>>>>>>>>>>>>>>>>>>>>>>>>>>>> 使用道具的效果 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 使用道具效果
function backpackLogic.useEffectNone(id, count, ...)
    return true
end

-- 使用货币道具效果
function backpackLogic.useEffectCurrency(id, count, ...)
    gLog.d("backpackLogic.useEffectCurrency", player:getUid(), id, count)
    --local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    --backpackCtrl:addItem(1, count)
    return true, {{id = 1, count = 1}}
end

-- 使用礼包道具效果
function backpackLogic.useEffectRewardPack(id, count, ...)
    gLog.d("backpackLogic.useEffectRewardPack", player:getUid(), id, count)
    --local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    --backpackCtrl:addItem(1, count)
    return true, {{id = 1, count = 1}}
end
---<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 使用道具的效果 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- 使用道具校验配置
backpackLogic.useCheck =
{
    [gItemTypeDef.CURRENCY] = backpackLogic.useCheckNone,
    [gItemTypeDef.ITEM_CURRENCY] = backpackLogic.useCheckNone,
    [gItemTypeDef.ITEM_NO_EFFECT] = backpackLogic.useCheckNone,
    [gItemTypeDef.ITEM_REWARD_PACK] = backpackLogic.useCheckRewardPack,
}

-- 使用道具效果
backpackLogic.useEffect =
{
    [gItemTypeDef.CURRENCY] = backpackLogic.useEffectNone,
    [gItemTypeDef.ITEM_CURRENCY] = backpackLogic.useEffectCurrency,
    [gItemTypeDef.ITEM_NO_EFFECT] = backpackLogic.useEffectNone,
    [gItemTypeDef.ITEM_REWARD_PACK] = backpackLogic.useEffectRewardPack,
}

-- 获取使用道具校验函数
function backpackLogic.useCheckFunc(type)
    return backpackLogic.useCheck[type]
end

-- 获取使用道具效果函数
function backpackLogic.useEffectFunc(type)
    return backpackLogic.useEffect[type]
end

return backpackLogic
