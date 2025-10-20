--[[
    行军队列基类
--]]
local skynet = require "skynet"
local queueConf = require "queueConf"
local queueUtils = require "queueUtils"
local playerDataLib = require "playerDataLib"
local queueCenter = require("queueCenter"):shareInstance()
local queueCell = class("queueCell")

-- 构造
function queueCell:ctor(id)
    self.module = "mapqueue"	        -- 数据表名
    self.id = id                        -- 数据ID
    self.data = nil		                -- 数据
end

-- 初始化
function queueCell:init(data)
    self.data = data or self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
end

-- 默认数据
function queueCell:defaultData()
    local ret = {
        id = self.id,               -- 队列ID
        ---- from ----
        uid = nil,                  -- 玩家ID
        aid = nil,                  -- 联盟ID
        queueType = nil,            -- 队列类型
        fromX = nil,                -- 出发点坐标X
        fromY = nil,                -- 出发点坐标Y
        fromMapType = nil,          -- 出发点地图对象类型
        fromSubMapType = nil,       -- 出发点地图对象子类型
        ---- to -----
        toId = nil,                 -- 目的点地图对象ID
        toX = nil,                  -- 目的点坐标X
        toY = nil,                  -- 目的点坐标X
        toMapType = nil,            -- 目的点地图对象类型
        toSubMapType = nil,         -- 目的点地图对象子类型
        toUid = nil,                -- 目的点玩家ID
        toAid = nil,                -- 目的点联盟ID
        ---- status ----
        status = nil,               -- 状态
        statusStartTime = nil,      -- 状态开始时间
        statusEndTime = nil,        -- 状态结束时间
        ---- army ------
        army = nil,                 -- 军队
        woundArmy = nil,            -- 伤兵
        loseArmy = nil,             -- 死兵
        ---- mass ----
        massTime = nil,             -- 集结时长
        mainQid = nil,              -- 集结主队列ID
        mainQueueType = nil,        -- 集结主队列类型
        maxMassNum = nil,           -- 集结士兵上限
        maxMassPlayer = nil,        -- 集结人数上限
        ---- settle ----
        isSettled = nil,            -- 是否已结算
        reward = nil,               -- 战利品
        physical = nil,             -- 消耗的体力
        createTime = nil,           -- 创建时间
    }
    return ret
end

-- 获取ID
function queueCell:getId()
    return self.id
end

-- 获取ID
function queueCell:setId(id)
    self.id = id
end

-- 重置数据, 用于回收
function queueCell:reset()
    self.id = nil
    self.data = nil
end

-- 设置属性
function queueCell:setAttr(k, v, bSave)
    if self.data[k] ~= v then
        self.data[k] = v
        if bSave then
            self:updateDB()
        end
        return true
    end
end

-- 获取属性
function queueCell:getAttr(k)
	return self.data[k]
end

-- 查询数据库
function queueCell:queryDB()
    assert(self.module and self.id, "queueCell:queryDB error!")
    return playerDataLib:query(queueCenter.kid, self.id, self.module)
end

-- 更新数据库
function queueCell:updateDB()
    assert(self.module and self.data, "queueCell:updateDB error!")
    playerDataLib:sendUpdate(queueCenter.kid, self.id, self.module, self.data)
end

-- 删除数据库
function queueCell:deleteDB()
    assert(self.module and self.id, "queueCell:updateDB error!")
    playerDataLib:sendDelete(queueCenter.kid, self.id, self.module)
    self:reset()
end

-- 队列创建时的处理
function queueCell:onCreate(...)
    if queueConf.massMainQueue[self:getAttr("queueType")] then
        self:initMassTime() -- 初始化集结时间
    else
        local ok, code = self:onMoving()
        if not ok then
            return code
        end
        self:initMoveTime() -- 初始化行军时间
    end
    return true
end

-- 队列出发时的处理
function queueCell:onMoving(...)
    return true
end

-- 队列抵达时的处理
function queueCell:onArrive(...)
    return true
end

-- 队列回城时的处理
function queueCell:onReturn(...)
    return true
end

-- 初始化集结时间
function queueCell:initMassTime()
    --gLog.i("queueCell:initMassTime")
    --local curTime = svrFunc.systemTime()
    --self:setAttr("statusStartTime", curTime)
    ---- DEBUG
    --if dbconf.DEBUG and self:getAttr("massTime") and self:getAttr("massTime") <= 300 then
    --    self:setAttr("massTime", self:getAttr("massTime")/10)
    --end
    --self:setAttr("statusEndTime", curTime + self:getAttr("massTime"))
    --self:setAttr("status", queueConf.queueStatus.massing)
    ---- 初始化移动时间
    --local moveTimeSpan = self:calMoveTimeSpan()
    --self:setAttr("moveTimeSpan", moveTimeSpan)
    --local totalTime = self:getTotalMoveTime()
    --self:setAttr("statusEndTimeOri", curTime + totalTime)
end

-- 初始化行军时间
function queueCell:initMoveTime()
    --gLog.d("queueCell:initMoveTime enter=", self:getId())
    --local totalTime, moveTimeSpan = self:calMoveTimeSpan()
    --local statusStartTime = svrFunc.systemTime()
    --local statusEndTime = statusStartTime + totalTime
    --self:setAttr("status", queueConf.queueStatus.moving)
    --self:setAttr("statusStartTime", statusStartTime)
    --self:setAttr("statusEndTime", statusEndTime)
    --self:setAttr("statusEndTimeOri", statusEndTime)
    --self:setAttr("moveTimeSpan", moveTimeSpan)
    --gLog.i("queueCell:initMoveTime end=", self:getId(), self:getQueueType(), self:getToId())
end

-- 获取串行队列键
function queueCell:getSqKey()
    return self:getAttr("toId")
end

-- 获取打包下发给客户端的数据
function queueCell:getPackInfo()
	local ret = self.data or {}
	return ret
end

function queueCell:getArmyNum(isOri)
    local count = 0
    local army = self:getAttr("army")
    if army then
        for _, cell in pairs(army) do
            count = count + cell.num
        end
    end
    return count
end

function queueCell:getWoundNum()
    local count = 0
    local army = self:getAttr("woundArmy")
    if army then
        for _, cell in pairs(army) do
            count = count + cell.num
        end
    end
    return count
end

function queueCell:getLoseNum()
    local count = 0
    local army = self:getAttr("loseArmy")
    if army then
        for _, cell in pairs(army) do
            count = count + cell.num
        end
    end
    return count
end

return queueCell