--[[
    行军队列服务中心
]]
local skynet = require "skynet"
local queueConf = require "queueConf"
local queueConf = require "queueConf"
local serviceCenterBase = require("serviceCenterBase2")
local queueCenter = class("queueCenter", serviceCenterBase)

-- 构造
function queueCenter:ctor()
    self.super.ctor(self)
    
    -- 消息队列
    self.msgQueue = {}
end

-- 初始化
function queueCenter:init(kid)
    gLog.i("==queueCenter:init begin==", kid)
    self.super.init(self, kid)

    -------------- 模块创建 --------------
    -- 队列行为逻辑
    self.queueCallbackLogic = require("queueCallbackLogic").new()
    -- 定时器管理
    self.queueTimerMgr = require("queueTimerMgr").new()
    -- 视野管理
    self.queueAoiMgr = require("queueAoiMgr").new()
    -- 队列对象管理
    self.queueCellMgr = require("queueCellMgr").new()

    -------------- 模块初始化 --------------
    ---- 队列对象管理初始化
    --self.queueCellMgr:init()
    ---- 视野管理初始化
    --local w, h = 1215, 1215
    --self.queueAoiMgr:init(w, h, queueConf.world_aoi_confs)

    gLog.i("==queueCenter:init end==", kid)
end

----------------------------------------服务端外部请求处理------------------------------------------
--[[
    请求创建行军队列
]]
function queueCenter:reqMarch(params)
    gLog.i("queueCenter:reqMarch=", params.uid, params.aid, params.queueType, params.toId, params.toMapType, params.toUid, params.toAid)
    if svrconf.DEBUG then
        gLog.dump(params, "queueCenter:reqMarch params=", 10)
    end
    -- 队列数量检查
    local queueMap = self.queueCellMgr:batchQuery(params.uid, queueConf.queueIndexKey.uid)
    local queueNum = table.nums(queueMap)
    if queueNum + 1 > queueConf.maxQueueNum then
        gLog.d("queueCenter:reqMarch error1", params.uid)
        return false, gErrDef.queue_num_limit
    end
    local ok, code = self.queueCellMgr:createQueue(params)
    if not ok then
        return false, code
    end
    local queue = code
    gLog.i("queueCenter:reqMarch ok=", queue:getId(), params.uid, params.aid, params.queueType, params.toId, params.toMapType, params.toUid, params.toAid)
    return true
end

-- 获取目标建筑驻扎部队数量
function queueCenter:getArmyHelpNum(uid, toId)
    gLog.d("queueCenter:getArmyHelpNum uid, toId =", uid, toId)
    local queueMap
    local massLimit
    if toId then
        queueMap = self.queueCellMgr:batchQuery(toId, queueConf.queueIndexKey.toId)
        local captainQueue = self:getCaptainQueue(toId)
        if captainQueue then
            massLimit = captainQueue:getAttr("massLimit")
        end
    elseif uid then
        -- 获取城堡援助兵力
        queueMap = self.queueCellMgr:batchQuery(uid, queueConf.queueIndexKey.toUid)
        toId = self:getCache(uid, gQueueCacheDataKey.castleId)
    else
        return
    end
    local curNum, maxNum, captainUid = 0, 0, nil
    for _, queue in pairs(queueMap) do
        gLog.d("queueCenter:getArmyHelpNum id =", queue:getId())
        if queue:isStaying() then
            curNum = curNum + queue:getArmyNum()
            if queue:getAttr("isCaptain") then
                maxNum = queue:getAttr("maxMassNum")
                captainUid = queue:getUid()
            end
        end
    end
    gLog.d("queueCenter:getArmyHelpNum curNum, maxNum, captainUid, toId, massLimit =", curNum, maxNum, captainUid, toId, massLimit)
    return curNum, maxNum, captainUid, toId, massLimit
end

--[[
    目前只处理采集速度加成变更
    effectType,techType 二选一
]]
function queueCenter:buffChange(uid, effectType, lordTechType, techType)
    --gLog.i("queueCenter:buffChange uid, effectType, lordTechType, techType =", uid, effectType, lordTechType, techType)
end

--[[
    遣返一条队列
    uid 可为空，若有值会判断该玩家是否有权限遣返队列
    skipMove bool 是否秒返
]]
function queueCenter:backSingleQueue(qid, uid, toId, skipMove, backType)
    gLog.d("queueCenter:backSingleQueue qid, uid, toId, skipMove, backType =", qid, uid, toId, skipMove, backType)
    local queue
    if qid then
        queue = self:getQueue(qid)
        if not queue then
            return gErrDef.Err_MAP_QUEUE_NOT_FOUND
        end
    elseif toId then
        local queueList = self:getOccupyQueue(toId)
        for _, fQueue in pairs(queueList) do
            if uid == fQueue:getUid() then
                queue = fQueue
                break
            end
        end
        if not queue then
            return gErrDef.Err_QUEUE_NOT_FOUND
        end
    else
        return gErrDef.Err_ILLEGAL_PARAMS
    end
    backType = backType or gQueueBackType.normal
    if gQueueBackType.normal == backType then
        if queueConf.queueType.massSlave == queue:getQueueType() then
            -- 是否集结主队列遣返集结子队列
            local mainQid = queue:getAttr("mainQid")
            local mainQueue = mainQid and self:getQueue(mainQid)
            if not mainQueue or uid ~= mainQueue:getUid() then
                return gErrDef.Err_ILLEGAL_PARAMS
            end
        elseif queue:isStaying() then
            -- 判断是否是援助自己的部队
            if not (queueConf.queueType.moveLineTypeArmyHelp == queue:getQueueType() and uid == queue:getAttr("toUid")) then
                if uid ~= queue:getUid() then
                    -- 判断是不是自己，不是自己就接着判断其他角色
                    -- 是否建筑队长、盟主、战神遣返
                    local captainQueue = self:getCaptainQueue(queue:getAttr("toId"))
                    if not captainQueue or uid ~= captainQueue:getUid() then
                        -- 判断是不是队长
                        -- 判断联盟身份
                        local _, _, invalid = self:checkInvalidOffice(uid)
                        if invalid then
                            return gErrDef.Err_ALLIANCE_NO_PERMISSION
                        end
                    end
                end
            end
        elseif queueConf.queueType.moveLineTypeArmyHelp == queue:getQueueType() then
            if uid ~= queue:getAttr("uid") and uid ~= queue:getAttr("toUid") then
                return gErrDef.Err_ILLEGAL_PARAMS
            end
        end
    elseif gQueueBackType.recall == backType then
        -- 只有自己可以召回自己的队列
        if uid ~= queue:getUid() then
            return gErrDef.Err_ILLEGAL_PARAMS
        end
        -- 集结子队列无法召回（主队列召回子队列用的是gQueueBackType.normal）
        if queueConf.queueType.massSlave == queue:getQueueType() then
            return gErrDef.Err_ILLEGAL_PARAMS
        end
        -- 召回只对行军中的队列有效
        if not queue:isMoving() then
            return gErrDef.Err_MAP_QUEUE_POS_CHANGE
        end
        -- 处于回调中的队列不接受召回请求，避免玩家多次消耗道具
        if queue:getCallbackLock() then
            return gErrDef.Err_MAP_QUEUE_POS_CHANGE
        end
    end
    return self:backQueue(queue, skipMove)
end

function queueCenter:backAllQueue()
    local queueMap = self.queueCellMgr.indexTable[queueConf.queueIndexKey.id]
    for _, cell in pairs(queueMap) do
        self:backQueue(queue, true)
    end
end

function queueCenter:reqSpeedQueue(uid, qid, reduceTimeRate)
    --gLog.i("queueCenter:reqSpeedQueue uid, qid, reduceTimeRate = ", uid, qid, reduceTimeRate)
    --local queue = self:getQueue(qid)
    --if not queue then
    --    return gErrDef.Err_QUEUE_NOT_FOUND
    --end
    --local queueType = queue:getQueueType()
    ---- 只有集结队列会被其他人加速
    --if uid ~= queue:getUid() and not (queueAttr:checkAttr(queueType, queueConf.queueAttr.mass) or queueAttr:checkAttr(queue:getAttr("queueTypeOri"), queueConf.queueAttr.mass)) then
    --    -- if queueAttr:checkAttr(queueType, queueConf.queueAttr.massMain) then
    --    --     -- 判断是否是子队列给主队列加速
    --    --     local isSuQueueUid = false
    --    --     local subQids = queue:getAttr("subQids")
    --    --     if subQids then
    --    --         for subQid, _ in pairs(subQids) do
    --    --             local subQueue = self:getQueue(subQid)
    --    --             if uid == subQueue:getUid() then
    --    --                 isSuQueueUid = true
    --    --                 break
    --    --             end
    --    --         end
    --    --     end
    --    --     if not isSuQueueUid then
    --    --         return gErrDef.Err_ILLEGAL_PARAMS
    --    --     end
    --    -- else
    --    --     return gErrDef.Err_MAP_QUEUE_NOT_FOUND
    --    -- end
    --    return gErrDef.Err_ILLEGAL_PARAMS
    --end
    --if queue:getCallbackLock() then
    --    gLog.w("queueCenter:reqSpeedQueue queue:getCallbackLock")
    --    return gErrDef.Err_MAP_QUEUE_POS_CHANGE
    --end
    ---- 已处于跟随状态下的子队列加速会默认给主队列加速(目前客户端子队列给主队列加速传的是主队列qid)
    ---- if queueConf.queueType.massSlave == queueType and queue:isFollowing() then
    ----     local mainQid = queue:getAttr("mainQid")
    ----     queue = self:getQueue(mainQid)
    ---- end
    --if not queue:isMoving() or not queue:getAttr("moveTimeSpan") then -- 队列类型转变期间moveTimeSpan为nil
    --    gLog.w("queueCenter:reqSpeedQueue queue not moving")
    --    return gErrDef.Err_MAP_QUEUE_POS_CHANGE
    --end
    ---- 判断是否有加速权限锁
    --if queue:getAttr("speedupLock") and uid ~= queue:getUid() and queueAttr:checkAttr(queueType, queueConf.queueAttr.massMain) then
    --    -- 只有r4以上可以加速
    --    local uidrank = self:checkInvalidOffice(uid)
    --    if uidrank < gAllianceRank.R4 then
    --        return gErrDef.Err_NO_SPEEDUP_PERMISSION
    --    end
    --end
    --local err = queue:speedUp(reduceTimeRate)
    --if err and gErrDef.Err_OK ~= err then
    --    return err
    --end
    --self:onUpdateQueue(queue)
    ---- 集结队列被加速后需要通知其他参与集结的玩家
    --if queueAttr:checkAttr(queueType, queueConf.queueAttr.massMain) then
    --    local noticeUids = {}
    --    if queue:getUid() ~= uid then
    --        table.insert(noticeUids, queue:getUid())
    --    end
    --    local subQids = queue:getAttr("subQids")
    --    if subQids then
    --        for subQid, _ in pairs(subQids) do
    --            local subQueue = self:getQueue(subQid)
    --            if subQueue and subQueue:getUid() ~= uid then
    --                table.insert(noticeUids, subQueue:getUid())
    --            end
    --        end
    --    end
    --    for _, uidF in pairs(noticeUids) do
    --        queueNotifyMgr:sendNotice(uidF, nil, "speedupMass", {nickName = nickName,})
    --    end
    --end
    --return gErrDef.Err_OK, {
    --    fromMapType = gWorldTypeDef.mapTypePlayer,
    --    toMapType = queue:getAttr("toMapType"),
    --}
end

-- 是否免战
function queueCenter:isForbidWar(queueType)
    gLog.d("queueCenter:isForbidWar queueType=", queueType)
    return false
end
----------------------------------------服务端外部请求处理 end------------------------------------------

----------------------------------------DEBUG------------------------------------------
function queueCenter:fixJamQueue(skipMove, onlyQuery)
    gLog.w("queueCenter:fixJamQueue start", skipMove)
    local queueMap = self.queueCellMgr.indexTable[queueConf.queueIndexKey.id]
    local curTime = svrFunc.systemTime()
    local ret
    for _, cell in pairs(queueMap) do
        for qid, queue in pairs(cell) do
            local needReturn
            local statusEndTime = queue:getAttr("statusEndTime")
            if not queue:getCallbackLock()
                    and (statusEndTime > 0 and (statusEndTime < curTime - 10)
                    or statusEndTime == 0 and queue:isStaying() and queueAttr:checkAttr(queueType, queueConf.queueAttr.collectMine)) then
                -- 超时未结算的队列、抵达后不采集的队列
                needReturn = true
            end
            if not needReturn and queue:isFollowing() then
                local mainQid = queue:getAttr("mainQid")
                local mainQueue = mainQid and self:getQueue(mainQid)
                if not mainQueue then
                    needReturn = true
                end
            end
            if needReturn then
                if not onlyQuery then
                    self.queueCallbackLogic:returnQueue(queue, skipMove)
                else
                    ret = ret or {}
                    table.insert(ret, {
                        qid = qid,
                        queueType = queue:getQueueType(),
                        callbackLock = queue:getCallbackLock(),
                        statusEndTime = statusEndTime,
                    })
                end
            end
        end
    end
    gLog.w("queueCenter:fixJamQueue done")
    return ret
end
----------------------------------------DEBUG end------------------------------------------






--玩家切换视野
function queueCenter:update_watcher(msg)
    return self.queueAoiMgr:update_watcher(msg.playerid, msg.address, msg.x, msg.y, msg.radius) or {}
end

function queueCenter:cancel_player_watch(playerid)
    self.queueAoiMgr:remove_watcher(playerid)
end

---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 队列对象维护开始 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 移除队列
function queueCenter:removeQueue(queue)
    if not queue then
        return
    end
    local qid = queue:getId()
    gLog.i("queueCenter:removeQueue qid=", qid)
    -- 删计时器
    self.queueTimerMgr:removeObjTimer(qid)
    -- 删对象
    self.queueCellMgr:remove(qid)
end

--[[
    包含了一个对象被修改以后所有的后续操作
]]
function queueCenter:onUpdateQueue(queue)
    if not queue:isValid() then
        return
    end
    gLog.d("queueCenter:onUpdateQueue", queue:getId())
    -- 判断是否需要自动返回（用于队列数据被动变更时触发的遣返，例如军队死光）
    if queue:needReturn() then
        -- 此处的fork用于避免在同一个sq里重入执行returnQueue
        skynet.fork(function()
            self.queueCallbackLogic:returnQueue(queue)
        end)
        return
    end
    -- 联军建筑驻扎部队的兵力一旦发生变化则需要通知联军服
    if queue:isStaying()
            and queue:popColChange("army") then
        if svrFunc.isForcesBuild(queue:getAttr("toMapType")) then
            unitedForcesLib:updateBuildingArmy(gKid, queue:getAttr("aid"), queue:getAttr("toId"), queue:getAttr("uid"), queue:getId(), queue:getAttr("army"))
        elseif gWorldTypeDef.mapTypeAllianceBuild == queue:getAttr("toMapType") then
            allianceLib.updateBuildingArmy(gKid, queue)
        end
    end
    -- 更新索引
    self.queueCellMgr:updateIndex(queue)
    -- 更新定时器
    self.queueTimerMgr:updateObjTimer(queue)
    -- 客户端推送
    queueNotifyMgr:updateQueue(queue)
end

--[[
    indexKey 默认为id
]]
function queueCenter:getQueue(qid, indexKey)
    if qid then
        return self.queueCellMgr:query(qid, indexKey)
    end
end

--[[
    返回队列
    skipMove bool 是否秒返
]]
function queueCenter:backQueue(queue, skipMove)
    gLog.i("queueCenter:backQueue", queue:getId(), queue:getQueueType(), skipMove)
    if not skipMove and queueConf.queueType.backHome == queue:getQueueType() then
        -- 返回队列无法再次执行返回
        return gErrDef.Err_MAP_QUEUE_STATUS_ERROR
    end
    self.queueCallbackLogic:returnQueue(queue, skipMove)
end

--[[
    获取集结队列的所有军队的整合军队信息
]]
function queueCenter:getMassArmy(qid)
    local queue = self:getQueue(qid)
    local ret = clone(queue:getAttr("army"))
    local subQids = queue:getAttr("subQids")
    if subQids then
        for subQid, _ in pairs(subQids) do
            local subQueue = self:getQueue(subQid)
            if subQueue then
                svrFunc.mergeArmy(ret, subQueue:getAttr("army"), true)
            end
        end
    end
    return ret
end

function queueCenter:getMassArmyNum(qid, onlyFollowing)
    local queue = self:getQueue(qid)
    local ret = queue:getArmyNum()
    local subQids = queue:getAttr("subQids")
    if subQids then
        for subQid, _ in pairs(subQids) do
            local subQueue = self:getQueue(subQid)
            if subQueue and (not onlyFollowing or subQueue:isFollowing()) then
                ret = ret + subQueue:getArmyNum()
            end
        end
    end
    return ret
end

-- 获取集结
function queueCenter:getMassQueueList()
    local subQids = queue:getAttr("subQids")
    local queueList
    if subQids then
        queueList = {}
        for subQid, _ in pairs(subQids) do
            local subQueue = self:getQueue(subQid)
            table.insert(queueList, subQueue)
        end
    end
    return queueList
end
----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 队列对象维护结束 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 启动顺序相关 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 加入到消息队列
function queueCenter:addToMsgQueue(fun, ...)
    local params = skynet.packstring(...)
    local msg = {responseClosure = skynet.response(), fun = fun, params = params}
    table.insert(self.msgQueue, msg)
end

-- 执行消息队列
function queueCenter:performMsgQueue()
    if not next(self.msgQueue) then
        return
    end
    gLog.i("queueCenter:performMsgQueue count=", #self.msgQueue)
    for i, msg in ipairs(self.msgQueue) do
        local responseClosure = msg.responseClosure
        local respondFun = msg.fun
        local params = msg.params
        gLog.i("queueCenter:performMsgQueue begin", i)
        skynet.fork(function()
            responseClosure(true, respondFun(self, skynet.unpack(params)))
        end)
        gLog.i("queueCenter:performMsgQueue finish", i)
    end
    self.msgQueue = {}
end
----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 启动顺序相关 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


return queueCenter
