--[[
    背包
--]]
local skynet = require("skynet")
local backpackConf = require("backpackConf")
local backpackLogic = require("backpackLogic")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local backpack = class("backpack")

-- 构造
function backpack:ctor(type)
    self.type = type    -- 背包类型
    self.curSize = 0    -- 当前容量
    self.maxSize = gBackpackMaxSize[type] or 100 -- 最大容量
    self.items = nil    -- 道具
end

-- 初始化
function backpack:init(items)
    self.items = items
end

-- 检查是否可以添加道具
function backpack:canAddItems(items)
    if "table" ~= type(items) or #items <= 0 then
        gLog.w("backpack:canAddItems fail", player:getUid())
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    local id, count, flag, tmpSize, maxSize = nil, nil, false, self.curSize, self:getMaxSize()
    for _, v_ in pairs(items) do
        if v_.count > 0 then
            id, count = v_.id, v_.count
            local maxCount = backpackConf:getMaxCount(id) -- 堆叠上限
            flag = false
            if maxCount == 1 then -- 不可堆叠
                tmpSize = tmpSize + count
                if tmpSize > maxSize then
                    gLog.w("backpack:canAddItems fail", player:getUid(), id, count)
                    return false, gErrDef.Err_BACKPACK_FULL
                end
            elseif maxCount == 0 then -- 可无限堆叠
                for k, v in ipairs(self.items) do
                    if v.id == id then
                        flag = true
                        break
                    end
                end
                if not flag then
                    tmpSize = tmpSize + 1
                    if tmpSize > maxSize then
                        gLog.w("backpack:canAddItems fail", player:getUid(), id, count)
                        return false, gErrDef.Err_BACKPACK_FULL
                    end
                end
            else -- 可堆叠
                for k, v in ipairs(self.items) do
                    if v.id == id and (v.count or 0) < maxCount then
                        flag = true
                        if (v.count or 0) + count <= maxCount then
                            count = 0
                            break
                        else
                            count = count - (maxCount - v.count)
                        end
                    end
                end
                if count > 0 then
                    tmpSize = tmpSize + math.ceil(count/maxCount)
                    if tmpSize > maxSize then
                        gLog.w("backpack:canAddItems fail", player:getUid(), id, count)
                        return false, gErrDef.Err_BACKPACK_FULL
                    end
                end
            end
        else
            gLog.w("backpack:canAddItems fail", player:getUid(), id, count)
            return false, gErrDef.Err_ILLEGAL_PARAMS
        end
    end
    return true
end

-- 添加道具
function backpack:addItems(items)
    --gLog.dump(items, "backpack.addItems", 10)
    if "table" ~= type(items) or #items <= 0 then
        gLog.e("backpack:addItems error", player:getUid(), table2string(items))
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    local flag, notify = false, {}
    for _, v in pairs(items) do
        if v.count > 0 then
            if self:_addItem(v.id, v.count, notify) then
                flag = true
            end
        end
    end
    -- 更新数据库
    if flag then
        self:updateDB()
    end
    -- 推送客户端
    if next(notify) then
        player:notifyMsg("notifyUpdateItemInfo", {type = self.type, items = notify,})
    end
    return true
end

-- 添加道具（内部方法）
function backpack:_addItem(id, count, notify)
    gLog.i("backpack:_addItem", player:getUid(), id, count)
    local maxCount = backpackConf:getMaxCount(id) -- 堆叠上限
    local flag = false
    if maxCount == 1 then -- 不可堆叠
        for i = 1, count do
            if self.curSize < self:getMaxSize() then
                local item = {
                    id = id,
                    count = 1,
                }
                table.insert(self.items, item)
                table.insert(notify, {idx = #self.items, item = item,})
                self.curSize = self.curSize + 1
                flag = true
            else
                break
            end
        end
    elseif maxCount == 0 then -- 可无限堆叠
        for k, v in ipairs(self.items) do
            if v.id == id then
                v.count = (v.count or 0) + count
                table.insert(notify, {idx = k, item = v,})
                flag = true
                break
            end
        end
        if not flag and self.curSize < self:getMaxSize() then
            local item = {
                id = id,
                count = count,
            }
            table.insert(self.items, item)
            table.insert(notify, {idx = #self.items, item = item,})
            self.curSize = self.curSize + 1
            flag = true
        end
    else -- 可堆叠
        for k, v in ipairs(self.items) do
            if v.id == id and (v.count or 0) < maxCount then
                flag = true
                if (v.count or 0) + count <= maxCount then
                    v.count = (v.count or 0) + count
                    count = 0
                    table.insert(notify, {idx = k, item = v,})
                    break
                else
                    count = count - (maxCount - v.count)
                    v.count = maxCount
                    table.insert(notify, {idx = k, item = v,})
                end
            end
        end
        if count > 0 then
            while(count > 0 and self.curSize < self:getMaxSize()) do
                if count <= maxCount then
                    local item = {
                        id = id,
                        count = count,
                    }
                    table.insert(self.items, item)
                    table.insert(notify, {idx = #self.items, item = item,})
                    self.curSize = self.curSize + 1
                    count = 0
                else
                    local item = {
                        id = id,
                        count = maxCount,
                    }
                    table.insert(self.items, item)
                    table.insert(notify, {idx = #self.items, item = item,})
                    self.curSize = self.curSize + 1
                    count = count - maxCount
                end
                flag = true
            end
        end
    end
    return flag
end

-- 使用道具校验
function backpack:canUseItem(id, count)
    if not id or id <= 0 or not count or count <= 0 then
        gLog.e("backpack.canUseItem error", player:getUid(), id, count)
        return false, gErrDef.Err_ILLEGAL_PARAMS
    end
    -- 校验道具数量是否足够
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        if item.id == id then
            if (item.count or 0) > count then
                count = 0
                break
            else
                count = count - (item.count or 0)
                if count <= 0 then
                    break
                end
            end
        end
    end
    if count > 0 then
        gLog.w("backpack.canUseItem fail", player:getUid(), id, count)
        return false, gErrDef.Err_ITEM_NOT_ENOUGH
    end
    return true
end

-- 使用道具
function backpack:useItem(id, count, check, ...)
    gLog.i("backpack.useItem", player:getUid(), id, count, check, ...)
    --
    local tp = backpackConf:getType(id)
    if not tp then
        gLog.e("backpack.useItem error", player:getUid(), id, count, tp)
        return false, gErrDef.Err_SERVICE_EXCEPTION
    end
    -- 使用多种种物品时, 已校验过
    if check ~= false then
        -- 使用道具校验
        local ok, err = self:canUseItem(id, count)
        if not ok then
            return false, err or gErrDef.Err_SERVICE_EXCEPTION
        end
        -- 使用道具校验
        local f = backpackLogic.useCheckFunc(tp)
        if type(f) == "function" then
            local ok, err = f(id, count, ...)
            if not ok then
                gLog.i("backpack.useItem fail", player:getUid(), id, count, tp)
                return ok, err or gErrDef.Err_SERVICE_EXCEPTION
            end
        else
            gLog.w("backpack.useItem no useCheckFunc", player:getUid(), id, count, tp)
        end
    end
    -- 扣除道具
    self:_useItem(id, count)
    -- 获取使用道具效果函数
    local f = backpackLogic.useEffectFunc(tp)
    if type(f) == "function" then
        local ok, extra = f(id, count, ...)
        if not ok then
            gLog.i("backpack.useItem fail", player:getUid(), id, count, tp)
            return ok, extra or gErrDef.Err_SERVICE_EXCEPTION
        end
        return true, extra
    else
        gLog.w("backpack.useItem no useEffectFunc", player:getUid(), id, count, tp)
        return true
    end
end

-- 扣除道具（内部方法）
function backpack:_useItem(id, count)
    gLog.i("_useItem", player:getUid(), id, count)
    local flag, notify = false, {}
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        if item.id == id then
            flag = true
            if (item.count or 0) > count then
                item.count = item.count - count
                table.insert(notify, {idx = i, item = item,})
                count = 0
                break
            else
                count = count - (item.count or 0)
                item.count = 0
                table.remove(self.items, i)
                table.insert(notify, {idx = i,})
                self.curSize = self.curSize - 1
                if count <= 0 then
                    break
                end
            end
        end
    end
    -- 更新数据库
    if flag then
        self:updateDB()
    end
    -- 推送客户端
    if next(notify) then
        player:notifyMsg("notifyUpdateItemInfo", {type = self.type, items = notify,})
    end
end

-- 扣除物品(和使用道具的区别是, 只检查道具数量是否足够, 不执行使用检查逻辑和使用效果逻辑)
function backpack:deductItem(id, count)
    gLog.i("backpack:deductItem", player:getUid(), id, count)
    -- 使用道具校验
    local ok, err = self:canUseItem(id, count)
    if not ok then
        return false, err or gErrDef.Err_SERVICE_EXCEPTION
    end
    -- 扣除物品
    self:_useItem(id, count)
    return true
end

-- 获取道具数量
function backpack:getItemCount(id)
    if id then
        local ret = 0
        for k,v in pairs(self.items) do
            if v.id == id then
                ret = ret + (v.count or 0)
            end
        end
        return ret
    else
        return #self.items
    end
end

-- 更新数据库
function backpack:updateDB()
    local backpackCtrl = player:getModule(gModuleDef.backpackModule)
    backpackCtrl:updateDB()
end

-- 获取最大容量
function backpack:getMaxSize()
    return self.maxSize
end

-- 获取数据
function backpack:getData()
    return self.items
end

return backpack