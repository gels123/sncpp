--[[
    背包/道具相关配置读取
]]
local sharedataLib = require("sharedataLib")
local backpackConf = class("backpackConf")

-- 获取配置
function backpackConf:getItemInfo()
    if not self.itemInfo then
        self.itemInfo = sharedataLib.query("LOCAL_ITEM_INFO")
    end
    return self.itemInfo
end

-- 获取道具配置
function backpackConf:getItem(id)
    local itemInfo = self:getItemInfo()
    return itemInfo[id]
end

-- 获取道具的背包类型
function backpackConf:getBackpackType(id)
    local itemInfo = self:getItemInfo()
    return itemInfo[id] and itemInfo[id].BackpackType
end

-- 获取道具的堆叠上限
function backpackConf:getMaxCount(id)
    local itemInfo = self:getItemInfo()
    return itemInfo[id] and itemInfo[id].MaxCount
end

-- 获取道具类型
function backpackConf:getType(id)
    local itemInfo = self:getItemInfo()
    return itemInfo[id] and itemInfo[id].Type
end

return backpackConf
