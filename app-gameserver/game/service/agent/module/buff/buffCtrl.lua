--[[
	buff模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local baseCtrl = require("baseCtrl")
local buffCtrl = class("buffCtrl", baseCtrl)

-- 构造
function buffCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "buffinfo" -- 数据表名
end

-- 初始化
function buffCtrl:init()
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
    gLog.dump(self.data, "buffCtrl:init self.data=")
    --
    if self.data.buffs then
        for buffId,v in pairs(self.data.buffs) do
            self.data.buffs[buffId] = require("buffCell").new(v)
        end
    end
    -- 更新倒计时
    self:updateTimer()
end

-- 默认数据
function buffCtrl:defaultData()
    return {
        v = 1,             -- 版本
        buffs = {},          -- buff列表
        effects = {},        -- 效果列表
    }
end

-- 获取buff初始化数据
function buffCtrl:getInitData()
    return self.data.effects or {}
end

-- 获取存库数据
function buffCtrl:getDataDB()
    local data = clone(self.data)
    for k,v in pairs(data.buffs) do
        data.buffs[k] = v:getData()
    end
    return data
end

-- 查询buff效果
-- @effect  效果类型, 必传, 见gBuffEffect
-- @source  来源类型, 选传, 见gBuffSource
function buffCtrl:queryBuff(effect, source)
    assert(effect)
    if self.data.effects and self.data.effects[effect] then
        if source then
            local ret = clone(self.data.effects[effect])
            if ret.detail then
                for k,v in pairs(ret.detail) do
                    if v.source ~= source then
                        ret.value = ret.value - v.value
                        ret.detail[k] = nil
                    end
                end
            end
            return ret
        else
            return self.data.effects[effect]
        end
    end
end

-- 查询buff效果
-- @effects  效果类型, 必传, 见gBuffEffect
-- @source  来源类型, 选传, 见gBuffSource
function buffCtrl:queryBuffs(effects, source)
    assert(effects and next(effects))
    local ret = {}
    for _,effect in pairs(effects) do
        ret[effect] = self:queryBuff(effect, source)
    end
    return ret
end

-- 添加buff
-- @buffId  buff配置ID, 必传
-- @source  buff来源, 必传, 见gBuffSource
-- @lastTime  buff持续时间, 选传, 不传则取配置的持续时间
function buffCtrl:addBuff(buffId, source, lastTime)
    assert(buffId and source)
    gLog.i("buffCtrl:addBuff", buffId, source, lastTime)
    -- 条件判断
    -- 添加buff
    lastTime = lastTime or 0
    local startTime = svrFunc.systemTime()
    local endTime = math.ceil(startTime + lastTime)
    local effect = gBuffEffect.atkPlus
    local value = 10
    local valueold = self.data.buffs[buffId] and self.data.buffs[buffId]:getAttr("value") or 0
    local info = {
        buffId = buffId,
        source = source,
        effect = effect,
        value = value,
        startTime = startTime,
        endTime = endTime,
    }
    local cell = require("buffCell").new(info)
    self.data.buffs[info.buffId] = cell
    -- 更新效果列表
    if not self.data.effects then
        self.data.effects = {}
    end
    if not self.data.effects[info.effect] then
        self.data.effects[info.effect] = {
            effect = info.effect,
            value = 0,
            detail = {},
        }
    end
    self.data.effects[info.effect].value = self.data.effects[info.effect].value + info.value - valueold
    self.data.effects[info.effect].detail[info.buffId] = info
    -- 存库
    self:updateDB()
    -- 更新倒计时
    self:updateTimer()
    -- 推送客户端
    player:notifyMsg("notifyUpdateBuff", {effect = effect, value = self.data.effects[info.effect].value, cell = info,})

    return true
end

-- 移除buff
-- @buffId  buff配置ID, 必传
function buffCtrl:removeBuff(buffId)
    assert(buffId)
    if self.data.buffs and self.data.buffs[buffId] then
        gLog.i("buffCtrl:removeBuff", buffId)
        local info = self.data.buffs[buffId]:getData()
        self.data.buffs[buffId] = nil
        if self.data.effects and self.data.effects[info.effect] then
            if self.data.effects[info.effect].detail and self.data.effects[info.effect].detail[buffId] then
                self.data.effects[info.effect].detail[buffId] = nil
                self.data.effects[info.effect].value = self.data.effects[info.effect].value - info.value
                -- 存库
                self:updateDB()
                -- 更新倒计时
                self:updateTimer()
                -- 推送客户端
                player:notifyMsg("notifyUpdateBuff", {effect = info.effect, value = self.data.effects[info.effect].value, cell = {buffId = buffId},})
                return true
            else
                gLog.e("buffCtrl:removeBuff error: wrong detail", buffId)
            end
        else
            gLog.e("buffCtrl:removeBuff error: wrong effects", buffId)
        end
    end
    return false
end

-- 更新buff倒计时
function buffCtrl:updateTimer()
    local nearTime = nil -- 最近的倒计时
    if self.data.buffs then
        local endTime = nil
        for k,v in pairs(self.data.buffs) do
            endTime = v:getAttr("endTime")
            if endTime and endTime > 0 then
                if not nearTime or endTime < nearTime then
                    nearTime = endTime
                end
            end
        end
    end
    --gLog.d("buffCtrl:updateTimer", player:getUid(), nearTime)
    agentCenter.timerMgr:updateTimer(player:getUid(), gAgentTimerType.buff, nearTime)
end

-- buff倒计时回调
function buffCtrl:timerCallback()
    local curTime = svrFunc.systemTime()
    if self.data.buffs then
        local buffId, endTime = nil, nil
        for k,v in pairs(self.data.buffs) do
            buffId, endTime = v:getAttr("buffId"), v:getAttr("endTime")
            if endTime and endTime > 0 and endTime <= curTime then
                local ok = xpcall(function()
                    gLog.i("buffCtrl:timerCallback removeBuff", player:getUid(), buffId, endTime)
                    self:removeBuff(buffId)
                end, svrFunc.exception)
                if not ok then -- 防止removeBuff报错导致死循环
                    self.data.buffs[buffId] = nil
                end
            end
        end
    end
    -- 更新buff倒计时
    self:updateTimer()
end

return buffCtrl
