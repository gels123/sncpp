--[[
	背包/道具模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local backpack = require("backpack")
local backpackConf = require("backpackConf")
local backpackLogic = require("backpackLogic")
local baseCtrl = require("baseCtrl")
local backpackCtrl = class("backpackCtrl", baseCtrl)

-- 构造
function backpackCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "backpack" -- 数据表名
    self.data = nil		     -- 数据
    self.backpacks = {}      -- 背包

    -- 物品背包
    local propsBackpack = backpack.new(gBackpackDef.PROPS)
    self.backpacks[gBackpackDef.PROPS] = propsBackpack
    -- 材料背包
    local materialBackpack = backpack.new(gBackpackDef.MATERIAL)
    self.backpacks[gBackpackDef.MATERIAL] = materialBackpack
    -- 宝石背包
    local jewelBackpack = backpack.new(gBackpackDef.JEWEL)
    self.backpacks[gBackpackDef.JEWEL] = jewelBackpack
end

-- 初始化
function backpackCtrl:init()
    if self.bInit then
        return
    end
    -- 设置已初始化
    self.bInit = true
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
    gLog.dump(self.data, "backpackCtrl:init self.data=")
    -- 初始化背包
    local flag = false
    for k,v in pairs(self.backpacks) do
        if not self.data[k] then
            self.data[k] = {}
            flag = true
        end
        v:init(self.data[k])
    end
    -- 更新数据库
    if flag then
        self:updateDB()
    end
end

-- 默认数据
function backpackCtrl:defaultData()
    return {
        [gBackpackDef.PROPS] = {},
        [gBackpackDef.MATERIAL] = {},
        [gBackpackDef.JEWEL] = {},
    }
end

-- 获取初始化数据
function backpackCtrl:getInitData()
    local ret = {}
    for k,backpack in pairs(self.backpacks) do
        ret[k] = {type = k, maxSize = backpack:getMaxSize(), items = backpack:getData(),}
    end
    return ret
end

-- 道具按背包分类
function backpackCtrl:classifyBackpack(items)
    -- 合并道具
    if #items > 1 then
        for i = #items, 1, -1 do
            for j = 1, i-1, 1 do
                if items[j] and items[j].id == items[i].id then
                    items[j].count = (items[j].count or 0) + items[i].count
                    table.remove(items, i)
                    break
                end
            end
        end
    end
    -- 按背包分类
    local ret = {}
    for i, item in ipairs(items) do
        local bType = backpackConf:getBackpackType(item.id)
        if bType then
            if not ret[bType] then
                ret[bType] = {}
            end
            item.id = math.floor(item.id)
            item.count = math.floor(item.count)
            if item.count ~= 0 then
                table.insert(ret[bType], item)
            end
        else
            gLog.e("backpackCtrl:classifyBackpack error", item.id, bType)
        end
    end
    return ret
end

-- 检查物品是否可以添加
-- @items 道具数组 eg.items={{id=1, count=10}}
function backpackCtrl:canAddItems(items)
    items = self:classifyBackpack(items)
    -- 检查是否可以添加物品
    for bType, items_ in pairs(items) do
        local ok, err = self.backpacks[bType]:canAddItems(items_)
        if not ok then
            return ok, err
        end 
    end
    return true
end

-- 添加单个物品
function backpackCtrl:addItem(id, count)
    return self:addItems({{id = id, count = count,}})
end

-- 添加多个物品
-- @items 道具数组 eg.items={{id=1, count=10}}
function backpackCtrl:addItems(items)
    gLog.dump(items, "backpackCtrl:addItems items=", 10)
    items = self:classifyBackpack(items)
    if type(items) ~= "table" or not next(items) then
        gLog.e("backpackCtrl:addItems error1", player:getUid(), table2string(items))
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    -- 检查是否可以添加物品
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        if not backpack then
            gLog.e("backpackCtrl:addItems error2", player:getUid())
            return false, gErrDef.Err_SERVICE_EXCEPTION
        end
        local ok, err = backpack:canAddItems(items_)
        if not ok then
            gLog.d("backpackCtrl:addItems fail3", player:getUid())
            return ok, err or gErrDef.Err_SERVICE_EXCEPTION
        end
    end
    -- 添加物品
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        local ok, err = backpack:addItems(items_)
        if not ok then
            gLog.w("backpackCtrl:addItems fail4", player:getUid(), ok, err)
        end
    end
    return true
end

-- 使用一种物品
function backpackCtrl:useItem(id, count, ...)
    id, count = math.floor(id), math.floor(count)
    if id <= 0 or count <= 0 or not backpackConf:getItem(id) then
        gLog.w("backpackCtrl:useItem error1", player:getUid(), id, count, ...)
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    -- 校验背包类型
    local bType = backpackConf:getBackpackType(id)
    local backpack = bType and self.backpacks[bType]
    if not bType or not backpack then
        gLog.w("backpackCtrl:useItem error2", player:getUid(), id, count, ...)
        return false, gErrDef.Err_SERVICE_EXCEPTION
    end
    --
    local ok, extra = backpack:useItem(id, count, true, ...)
    if not ok then
        gLog.w("backpackCtrl:useItem error3", player:getUid(), id, count, ...)
        return ok, extra or gErrDef.Err_SERVICE_EXCEPTION
    end
    return ok, extra
end

-- 使用多种种物品
-- @items 道具数组 eg.items={{id=1, count=10}}
function backpackCtrl:useItems(items, ...)
    if type(items) ~= "table" or not next(items) then
        gLog.w("backpackCtrl:useItems error1", player:getUid(), table2string(items))
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    items = self:classifyBackpack(items)
    -- 校验使用多种物品
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        if not backpack then
            gLog.w("backpackCtrl:useItems error2", player:getUid())
            return false, gErrDef.Err_SERVICE_EXCEPTION
        end
        for _,item in ipairs(items_) do
            local id, count = item.id, item.count
            -- 使用道具校验
            local ok, err = backpack:canUseItem(id, count)
            if not ok then
                gLog.w("backpackCtrl:useItems error3", player:getUid(), id, count)
                return ok, err or gErrDef.Err_SERVICE_EXCEPTION
            end
            -- 使用道具校验
            local f = backpackLogic.useCheckFunc(bType)
            if type(f) == "function" then
                local ok, err = f(id, count, ...)
                if not ok then
                    gLog.w("backpackCtrl:useItems error4", player:getUid(), id, count)
                    return ok, err or gErrDef.Err_SERVICE_EXCEPTION
                end
            else
                gLog.w("backpack.useItems no useCheckFunc", player:getUid(), id, count)
            end
        end
    end
    -- 使用多种物品
    local extra = {}
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        for _,item in ipairs(items_) do
            local ok, extra_ = backpack:useItem(item.id, item.count, false, ...)
            if ok then
                table.append(extra, extra_)
            end
        end
    end
    return true, extra
end

-- 扣除物品
function backpackCtrl:deductItem(id, count)
    id, count = math.floor(id), math.floor(count)
    if id <= 0 or count <= 0 or not backpackConf:getItem(id) then
        gLog.w("backpackCtrl:deductItem error1", player:getUid(), id, count)
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    -- 校验背包类型
    local bType = backpackConf:getBackpackType(id)
    local backpack = bType and self.backpacks[bType]
    if not bType or not backpack then
        gLog.w("backpackCtrl:deductItem error2", player:getUid(), id, count)
        return false, gErrDef.Err_SERVICE_EXCEPTION
    end
    -- 扣除物品
    local ok, err = backpack:deductItem(id, count)
    if not ok then
        gLog.w("backpackCtrl:deductItem error3", player:getUid(), id, count)
        return ok, err or gErrDef.Err_SERVICE_EXCEPTION
    end
    return true
end

-- 扣除多个物品
function backpackCtrl:deductItems(items)
    if type(items) ~= "table" or not next(items) then
        gLog.w("backpackCtrl:deductItems error1", player:getUid(), table2string(items))
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    items = self:classifyBackpack(items)
    -- 校验使用多种物品
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        if not backpack then
            gLog.w("backpackCtrl:deductItems error2", player:getUid(), bType)
            return false, gErrDef.Err_SERVICE_EXCEPTION
        end
        for _,item in ipairs(items_) do
            local id, count = item.id, item.count
            -- 使用道具校验
            local ok, err = backpack:canUseItem(id, count)
            if not ok then
                gLog.w("backpackCtrl:deductItems error3", player:getUid(), id, count)
                return ok, err or gErrDef.Err_SERVICE_EXCEPTION
            end
        end
    end
    for bType, items_ in pairs(items) do
        local backpack = self.backpacks[bType]
        for _,item in ipairs(items_) do
            -- 扣除物品
            backpack:_useItem(item.id, item.count)
        end
    end
    return true
end

-- 获取背包
function backpackCtrl:getBackpack(bType)
    return self.backpacks[bType]
end

-- 清空背包
function backpackCtrl:clearBackpack()
    for _, backpack in pairs(self.backpacks) do
        local items = backpack:getData()
        if next(items) then
            self:deductItems(items)
        end
    end
    return true
end

return backpackCtrl
