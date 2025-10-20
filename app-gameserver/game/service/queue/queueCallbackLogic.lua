--[[
	队列行为逻辑
]]
local skynet = require "skynet"
local queueConf = require "queueConf"
local skynetQueue = require "skynet.queue"
local queueCenter = require("queueCenter"):shareInstance()
local queueCallbackLogic = class("queueCallbackLogic")

-- 
function queueCallbackLogic:ctor()
    -- 串行队列
    self.sq = {}
end

--[[
    队列定时器回调入口
]]
function queueCallbackLogic:timerCallback(param)
    local qid = param.id
    local timerType = param.timerType
    gLog.i("queueCallbackLogic:timerCallback qid=", qid, "timerType=", timerType)
    local hasTimer = queueCenter.queueTimerMgr:removeObjTimer(qid, timerType)
    -- 仅成功删除当前定时器时才触发回调逻辑
    if hasTimer then
        local queue = queueCenter:getQueue(qid)
        if not queue then
            gLog.w("queueCallbackLogic:timerCallback error1=", qid, timerType)
        else
            if queue:isMassing() then
                self:onQueueMassingEnd(queue)
            elseif queue:isMoving() then
                self:onQueueArrive(queue)
            elseif queue:isStaying() then
                self:returnQueue(queue)
            end
        end
    else
        -- 由于计时器触发逻辑使用了fork，所以在删除计时器的瞬间，可能已经触发了计时器，所以一些极端情况下，删除计时器后依然会触发计时器
        gLog.w("queueCallbackLogic:timerCallback error2=", qid, timerType)
    end
end

--[[
	队列集结完毕
]]
function queueCallbackLogic:onQueueMassingEnd(queue)
    -- -- 抵达检查
    -- local code = self:targetCheck(queue)
    -- if gErrDef.Err_OK ~= code then
    --     queueNotifyMgr:sendNotice(queue:getUid(), code)
    --     self:returnQueue(queue, nil, code)
    --     return
    -- end
    -- local code = queue:onMoving()
    -- if code and gErrDef.Err_OK ~= code then
    --     local uid = queue:getUid()
    --     self:returnQueue(queue, nil, code)
    --     queueNotifyMgr:sendNotice(uid, code)
    --     gLog.i("queueCallbackLogic:onQueueMassingEnd onMoving code ", code)
    --     return
    -- end
    -- local qid = queue:getId()
    -- -- 未抵达的子队列设置目标失效
    -- local subQids = queue:getAttr("subQids")
    -- if subQids then
    --     for subQid, _ in pairs(clone(subQids)) do
    --         -- 循环过程中会修改subQids
    --         local subQueue = queueCallbackLogic:getQueue(subQid)
    --         if subQueue and not subQueue:isFollowing() then
    --             local changeQidMap = self:clearMass(nil, subQid)
    --             if changeQidMap[subQid] then
    --                 queueCallbackLogic:onUpdateQueue(subQueue)
    --             end
    --         elseif not subQueue then
    --             queue:removeSubQid(subQid)
    --             svrFunc.error("queueCallbackLogic:onQueueMassingEnd subQueue not found ", qid, subQid)
    --         end
    --     end
    -- end
    -- -- 计算行军时间
    -- queueCallbackLogic:onUpdateQueue(queue)
end

--[[
	队列抵达
]]
function queueCallbackLogic:onQueueArrive(queue)
    skynet.fork(function()
        local qid, queueType, uid = queue:getId(), queue:getQueueType(), queue:getUid()
        gLog.i("queueCallbackLogic:onQueueArrive qid, queueType, uid=", qid, queueType, uid)
        local sq = self:getSkynetQueue(queue:getSqKey())
        sq(function()
            -- 回调锁检查
            if queue:getCallbackLock() then
                svrFunc.exception(string.format("queueCallbackLogic:onQueueArrive error1: %s %s %s", qid, queueType, uid))
                return
            end
            queue:setCallbackLock(true)

            xpcall(function()
                queue:setAttr("isSettled", true)
                -- 抵达检查
                local ok, code = self:targetCheck(queue)
                if not ok then
                    self:returnQueue(queue, nil, code)
                    -- 推送客户端

                    gLog.i("queueCallbackLogic:onQueueArrive targetCheck code", code)
                    return
                end
                -- 执行抵达逻辑
                local startTime = svrFunc.skynetTime()
                local ok, code = queue:onArrive()
                local optTime = svrFunc.skynetTime() - startTime
                if optTime > 1 then
                    gLog.w("queueCallbackLogic:onQueueArrive onArrive timeout =", qid, queueType, uid, "optTime=", optTime)
                end
                if not ok then
                    gLog.i("queueCallbackLogic:onQueueArrive onArrive error ", qid, queueType, uid)
                    self:returnQueue(queue, nil, code)
                    -- queueNotifyMgr:sendNotice(uid, code)
                    return
                else
                    -- queueNotifyMgr:sendNotice(uid, nil, "arrive")
                end
            end, svrFunc.exception)

            if queue then
                -- 解除回调锁
                queue:setCallbackLock(nil)
                -- 队列状态校验(有可能此时队列对象已经回收并且被再次使用，这样qid就会发生变化，但这种属于正常情况)
                -- if qid == queue:getId() and queue:isMoving() and queueConf.queueType.backHome ~= queue:getQueueType() then
                --     -- 如果抵达后队列依然维持移动状态并且不是返回队列，那一定是卡队列
                --     svrFunc.error("queueCallbackLogic:onQueueArrive exception ", queue:getId(), queue:getQueueType())
                --     self:returnQueue(queue, nil, gErrDef.Err_SERVICE_EXCEPTION)
                -- end
            end
        end)
    end)
end

--[[
	队列抵达公共检查
]]
function queueCallbackLogic:targetCheck(queue)
    local qid, uid, toUid, aid, queueType, toId, toMapType, isTargetMoved, toX, toY = queue:getId(), queue:getUid(), queue:getAttr("toUid"), queue:getAid(), queue:getQueueType(), queue:getAttr("toId"), queue:getAttr("toMapType"), queue:getAttr("isTargetMoved"), queue:getAttr("toX"), queue:getAttr("toY")
    -- 返回队列不用检查
    if queueConf.queueType.backHome == queueType then
        return true
    end
    -- 判断免战
    if queueCenter:isForbidWar(queueType) then
        gLog.d("queueCallbackLogic:targetCheck error1", qid, uid, queueType, toId, toMapType)
        return false, gErrDef.Err_MAP_QUEUE_FORBIT_WAR_TIME
    end
    -- 目标是否失效
    if isTargetMoved then
        gLog.d("queueCallbackLogic:targetCheck error2", qid, uid, queueType, toId, toMapType)
        return false, gErrDef.Err_MAP_QUEUE_POS_CHANGE
    end
	return true
end
































--[[
	驻扎队列
]]
function queueCallbackLogic:stayQueue(queue, mainQueueType, isDelayUpdate, toCfgId)
    gLog.i("queueCallbackLogic:stayQueue", queue:getId())
    if queue:getArmyNum() > 0 then
        -- 驻扎队列
        if queueConf.queueType.massSlave ~= queue:getQueueType() then
            -- 非子队列直接更改状态
            queue:setAttr("status", queueConf.queueStatus.staying)
            queue:setAttr("statusStartTime", svrFunc.systemTime())
            queue:setAttr("statusEndTime", 0)
            -- 刷新目标驻扎联盟，队长选定
            queueCallbackLogic:onOccupyIn(queue)
            if not isDelayUpdate then
                queueCallbackLogic:onUpdateQueue(queue)
            end
        else
            -- 子队列驻扎后会转化为其他类型的队列
            if mainQueueType then
                local singleQueueType = queueAttr:getSingleQueueType(mainQueueType)
                self:changeQueueType(queue, singleQueueType, toCfgId) -- 里面会执行onOccupyIn onUpdateQueue
            else
                gLog.w("queueCallbackLogic:stayQueue mainQueueType miss")
                return
            end
        end
    else
        -- 士兵死光直接返回
        self:returnQueue(queue)
    end
end

function queueCallbackLogic:stayMassQueue(queue)
    gLog.i("queueCallbackLogic:stayMassQueue", queue:getId())
    local subQueueList, mainQueueType, toCfgId
    if queueAttr:checkAttr(queue:getQueueType(), queueConf.queueAttr.massMain) then
        -- 主队列
        -- 主队列驻扎后，需要连带驻扎子队列
        mainQueueType = queue:getQueueType()
        toCfgId = queue:getAttr("toCfgId")
        local subQids = queue:getAttr("subQids")
        if subQids then
            for subQid, _ in pairs(subQids) do
                local subQueue = queueCallbackLogic:getQueue(subQid)
                if subQueue then
                    subQueueList = subQueueList or {}
                    table.insert(subQueueList, subQueue)
                end
            end
        end
    end
    -- 清除主从关系，避免主队列秒回导致不该回去从队列也被遣返了
    self:clearMass(queue:getId())
    -- 主队列入驻
    self:stayQueue(queue)
    -- 处理子队列驻扎(必须在主队列之后执行)
    if subQueueList then
        for _, subQueue in pairs(subQueueList) do
            self:stayQueue(subQueue, mainQueueType, nil, toCfgId)
        end
    end
end

--[[
	返回队列
	   code 因异常原因导致队列返回的时候传入异常
]]
function queueCallbackLogic:returnQueue(queue, skipMove, code)
    if not queue then
        gLog.e("queueCallbackLogic:returnQueue 1=", skipMove, code)
        return
    end
    local qid, queueType = queue:getId(), queue:getQueueType()
    -- 一些队列返回时直接销毁
    if queueConf.noReturnQueue[queueType] then
        gLog.i("queueCallbackLogic:returnQueue 2=", qid, queueType, skipMove, code)
        queueCenter:removeQueue(queue)
        return
    end
    -- 校验是否重复回城
    if queueConf.queueType.backHome == queue:getQueueType() and not skipMove then
        gLog.w("queueCallbackLogic:returnQueue 3=", qid, queueType, skipMove, code)
        return
    end
    -- 删除队列statusEnd计时器, 避免返回过程中重入执行队列抵达回调
    queueCenter.queueTimerMgr:removeObjTimer(qid, queueConf.queueTimerType.statusEndTime)
    -- 返回队列再次收到秒返请求, 则直接结算
    if queueConf.queueType.backHome == queue:getQueueType() and skipMove then
        gLog.i("queueCallbackLogic:returnQueue 4=", qid, queueType, skipMove, code)
        self:settleQueue(queue)
        return
    end
    gLog.i("queueCallbackLogic:returnQueue 5=", qid, queueType, skipMove, code)
    -- 队长队列遣返需要检查目标建筑的队长和归属联盟是否变更
    local isOccupyChange, oldToId, oldToMapType, oldToBelongAid, oldIsCaptain, oldToCfgId, toUid
    if queue:isStaying() then
        isOccupyChange = true
        oldToId, oldToMapType, oldToBelongAid, oldIsCaptain, oldToCfgId, toUid = queue:getToId(), queue:getAttr("toMapType"), queue:getAttr("toBelongAid"), queue:getAttr("isCaptain"), queue:getAttr("toCfgId"), queue:getAttr("toUid")
    elseif queue:isMoving() then
        -- 部分老版队列抵达后如果报错，会直接解散集结，各回各家
        if code and gErrDef.Err_OK ~= code and queueAttr:checkAttr(queue:getQueueType(), queueConf.queueAttr.compatibleErrorReturn) then
            self:returnSubQueue(queue)
        end
    end
    queue:onReturn(code)
    if skipMove or queue:isMassing() or not queueAttr:checkAttr(queue:getQueueType(), queueConf.queueAttr.noArmy) and queue:getArmyNum() <= 0 then
        self:settleQueue(queue)
    else
        -- 将队列转化为返回队列
        self:changeQueueType(queue, queueConf.queueType.backHome)
    end
    if isOccupyChange then
        queueCallbackLogic:onOccupyOut(qid, uid, oldToId, oldToMapType, oldToBelongAid, oldIsCaptain, oldToCfgId, toUid)
    end
end

function queueCallbackLogic:returnSubQueue(queue)
	local subQids = queue:getAttr("subQids")
	local subQueues = {}
	if subQids then
		for subQid, _ in pairs(subQids) do
			local subQueue = queueCallbackLogic:getQueue(subQid)
			table.insert(subQueues, subQueue)
		end
	end
	-- 清除主队列与子队列的关联，这样子队列才会从目标点返回
	self:clearMass(queue:getId())
	-- 打输返回
	for _, subQueue in pairs(subQueues) do
		self:returnQueue(subQueue)
	end
end

--[[
	结算队列
]]
function queueCallbackLogic:settleQueue(queue)
    gLog.i("queueCallbackLogic:settleQueue qid =", queue:getId())
    if queue:getIsSettled() then
        svrFunc.error("queueCallbackLogic:settleQueue queue has Settled", queue:getId())
        return
    end
    queue:setIsSettled(true)
    -- 实现未抵达目标点的主队列返回城堡时解散所有集结子队列的逻辑
    local subQids = queue:getAttr("subQids")
    if subQids and next(subQids) then
        -- 结算主队列要先遣返子队列
        self:clearMass(queue:getId())
        for subQid, _ in pairs(subQids) do
            local subQueue = queueCallbackLogic:getQueue(subQid)
            if subQueue then
                self:returnQueue(subQueue)
            end
        end
    end
    -- 开始结算
    local add = {}
    local army = queue:getAttr("army")

    -- lnk debug
    if queue:getArmyNum() > queue:getArmyNum(true) + 10000 then
        -- 结算兵力大于原始兵力
        svrFunc.error("queueCallbackLogic:settleQueue find error id, num, orgNum  =", queue:getId(), queue:getArmyNum(), queue:getArmyNum(true))
        army = queue:getAttr("availableArmyClone")
    end

    if army then
        for index, cell in pairs(army) do
            if cell.num > 0 then
                add[tostring(cell.id)] = cell.num
            end
        end
    end
    local wounded = {}
    local woundArmy = queue:getAttr("woundArmy")
    if woundArmy then
        for _, cell in pairs(woundArmy) do
            if cell.num > 0 then
                wounded[tostring(cell.id)] = cell.num
            end
        end
    end
    local spoils = queue:getAttr("spoils")
    if spoils then
        for k, v in pairs(spoils) do
            spoils[k] = svrFunc.getIntPart(v)
        end
    end
    local saveResource = queue:getAttr("saveResource")
    if saveResource then
        for k, v in pairs(saveResource) do
            saveResource[k] = svrFunc.getIntPart(v)
        end
    end
    local heroIDList = queue:getHeroIdList()
    local pet = queue:getAttr("pet")
    if next(add) or next(wounded) or spoils and next(spoils) or saveResource and next(saveResource) or heroIDList and next(heroIDList) or pet and next(pet) then
        local settleData = {
            add = add, -- 存活兵力
            wounded = wounded, -- 受伤兵力
            spoils = spoils, -- 获得资源
            saveResource = saveResource, -- 保护资源
            heroIDList = heroIDList,
            pet = pet,
            queueId = queue:getId(),
            orgQueueId = queue:getId(),
            queueType = queue:getAttr("queueType"),
        }
        gLog.dump(settleData, "queueCallbackLogic:settleQueue settleData")
        local playerProxy = queue:getPlayerProxy()
        playerProxy:settleQueue(settleData)
    else
        local loseArmy = queue:getAttr("loseArmy")
        if loseArmy and next(loseArmy) then
            -- 判断是否需要更新玩家战力
            local playerProxy = queue:getPlayerProxy()
            playerProxy:updateArmyPower(queue:getId(), gPowerAction.mapQueue)
        end
    end
    gLog.i("queueCallbackLogic:settleQueue playerProxy:settleQueue done qid =", queue:getId())
    -- 发送结算邮件（只有部分队列会发送）
    local settleMail = queue:getAttr("settleMail")
    queue:setAttr("settleMail", nil)
    if settleMail then
        local backReason = queue:getBackReason()
        if gResultPlayerQueueReasonType.moveOtherKingdom == backReason then
            -- 跨服迁城的情况需要用call，避免邮件没发完，玩家已经迁走了
            gLog.i("queueCallbackLogic:settleQueue call settleMail start", queue:getId())
            queueCallbackLogic:getMailServiceAPI():callSendCustomMail(settleMail.receivers, nil, settleMail.receiver, settleMail.mailType, settleMail.source, settleMail.emailData, settleMail.extra)
        else
            queueCallbackLogic:getMailServiceAPI():sendCustomMail(settleMail.receivers, nil, settleMail.receiver, settleMail.mailType, settleMail.source, settleMail.emailData, settleMail.extra)
        end
        gLog.i("queueCallbackLogic:settleQueue send settleMail done qid =", queue:getId())
    end

    -- 删除队列
    queueCenter:removeQueue(queue)
end

--[[
	转换队列类型
	目前存在的队列类型转换场景有
	1、队列返回
	2、子队列抵达目的地成为驻扎队列
	3、进攻资源田队列进攻成功后成为采集队列
]]
function queueCallbackLogic:changeQueueType(queue, queueType)
    if not queue or not queueType then
        gLog.e("queueCallbackLogic:changeQueueType 1=", queueType)
        return
    end
    local qid, oldQueueType = queue:getId(), queue:getQueueType()
    if queueType == oldQueueType then
        gLog.e("queueCallbackLogic:changeQueueType 2=", qid, queueType, oldQueueType)
        return
    end
    gLog.i("queueCallbackLogic:changeQueueType 3=", qid, oldQueueType, queueType)
    
    queue:setAttr("queueType", queueType)
    queue:setAttr("queueTypeOri", oldQueueType)
    if queueConf.queueType.backHome == queueType then
        -- 回城队列
        self:trans2ReturnQueue(queue)
    elseif queueConf.queueType.massSlave == oldQueueType then
        -- 集结子队列转驻扎队列
        queue:setAttr("status", queueConf.queueStatus.staying)
        queue:setAttr("statusStartTime", svrFunc.systemTime())
        queue:setAttr("statusEndTime", 0)
        queueCallbackLogic:onOccupyIn(queue)
    elseif queueConf.queueType.collectMine == queueType then
        -- 进攻资源田队列转采集队列
        queue:setAttr("status", queueConf.queueStatus.staying)
        queue:setAttr("statusStartTime", svrFunc.systemTime())
        queue:setAttr("statusEndTime", 0)
        queueCallbackLogic:onOccupyIn(queue)
    end
    queueCallbackLogic:onUpdateQueue(queue)
    queue:setCallbackLock(false)
end

function queueCallbackLogic:trans2ReturnQueue(queue)
    local fromX, fromY, toX, toY = queue:getAttr("fromX"), queue:getAttr("fromY"), queue:getAttr("toX"), queue:getAttr("toY")
    queue:setAttr("fromX", toX)
    queue:setAttr("fromY", toY)
    queue:setAttr("toX", fromX)
    queue:setAttr("toY", fromY)
    queue:setSqKey(queue:getToId()) -- 避免toId的变化导致其他请求绕过sq重入执行队列回调动作
    queue:setAttr("orgToId", queue:getToId())
    queue:setAttr("toId", svrFunc.generateMapObjId(fromX, fromY))
    queue:setAttr("fromMapType", queue:getAttr("toMapType"))
    queue:setAttr("fromSubMapType", queue:getAttr("toSubMapType"))
    queue:setAttr("toMapType", gWorldTypeDef.mapTypePlayer)
    queue:setAttr("toSubMapType", nil)
    queue:setAttr("toUid", nil)
    queue:setAttr("isTargetMoved", nil)
    local startDistanceRate
    if queue:isMoving() then
        -- 正在行军的队列返回时需要做行军路径补偿
        local distanceRate = queue:getMovedDistanceRate()
        if distanceRate and distanceRate < 1 then
            startDistanceRate = 1 - distanceRate
        end
    end
    queue:setAttr("moveTimeSpan", nil)
    queue:initMoveTime(startDistanceRate)
    queue:setSqKey(nil) -- 此后这条队列再次进入sq就不是之前的sq了
end

-- 为队列切换类型获取一份新unit组建的初始数据
function queueCallbackLogic:getNewUnitProperty(queue, queueType)
    local newUnitProperty = {}
    if queueConf.queueType.backHome == queueType then
        local oldUnit = queue:getUnit()
        local spoils = oldUnit:getAttr("spoils")
        if spoils and next(spoils) then
            newUnitProperty.spoils = spoils
        end
    elseif queueConf.queueType.collectMine == queueType
            or queueConf.queueType.moveLineTypeCollRune == queueType
    then
        local armyWeightPlus, starArmyOnlyWeightPlus = queue:getPlayerProxy():getWeightPlus(queue:getHeroIdList())
        newUnitProperty.weightPlus = armyWeightPlus
        newUnitProperty.starArmyOnlyWeightPlus = starArmyOnlyWeightPlus
    end
    return newUnitProperty
end

--[[
	去除队列的集结信息
	mainQid 与subQid互斥，表示清除主队列的所有集结信息，并修改子队列信息
	subQid 与mainQid互斥，表示清除子队列的所有集结信息，并修改主队列信息
	return changeQidMap 表示本次操作中进行了信息修改的队列id
]]
function queueCallbackLogic:clearMass(mainQid, subQid)
    gLog.i("queueCallbackLogic:clearMass mainQid, subQid =", mainQid, subQid)
    local changeQidMap = {}
    if mainQid then
        local queue = queueCallbackLogic:getQueue(mainQid)
        if queue then
            local subQids = queue:getAttr("subQids")
            if subQids and next(subQids) then
                queue:setAttr("subQids", nil)
                queue:setAttr("massTime", nil) -- 用来让客户端识别是否为集结队列
                changeQidMap[mainQid] = true
                for fSubQid, _ in pairs(subQids) do
                    local subQueue = queueCallbackLogic:getQueue(fSubQid)
                    if subQueue and subQueue:getAttr("mainQid") then
                        subQueue:setAttr("mainQid", nil)
                        subQueue:setAttr("massTime", nil) -- 用来让客户端识别是否为集结队列
                        -- 主队列抵达后，成功参与集结的子队列都要从主队列的目标返回
                        if subQueue:isFollowing() and queue:getAttr("isArrived") then
                            subQueue:setAttr("toId", queue:getAttr("toId"))
                            subQueue:setAttr("toMapType", queue:getAttr("toMapType"))
                            subQueue:setAttr("toSubMapType", queue:getAttr("toSubMapType"))
                            subQueue:setAttr("toRefreshId", queue:getAttr("toRefreshId"))
                            subQueue:setAttr("toCfgId", queue:getAttr("toCfgId"))
                            subQueue:setAttr("toUid", queue:getAttr("toUid"))
                            subQueue:setAttr("toBelongAid", queue:getAttr("toBelongAid"))
                            subQueue:setAttr("toX", queue:getAttr("toX"))
                            subQueue:setAttr("toY", queue:getAttr("toY"))
                        end
                        changeQidMap[fSubQid] = true
                    end
                end
            end
        end
    elseif subQid then
        local queue = queueCallbackLogic:getQueue(subQid)
        if queue then
            local mainQid = queue:getAttr("mainQid")
            if mainQid then
                queue:setAttr("mainQid", nil)
                if not queue:isFollowing() then
                    queue:setAttr("isTargetMoved", true)
                end
                queue:setAttr("massTime", nil) -- 用来让客户端识别是否为集结队列
                changeQidMap[subQid] = true
                local mainQueue = queueCallbackLogic:getQueue(mainQid)
                if mainQueue then
                    if mainQueue:removeSubQid(subQid) then
                        changeQidMap[mainQid] = true
                    end
                    -- 主队列抵达后，成功参与集结的子队列都要从主队列的目标返回
                    if queue:isFollowing() and mainQueue:getAttr("isArrived") then
                        queue:setAttr("toId", mainQueue:getAttr("toId"))
                        queue:setAttr("toMapType", mainQueue:getAttr("toMapType"))
                        queue:setAttr("toSubMapType", mainQueue:getAttr("toSubMapType"))
                        queue:setAttr("toRefreshId", mainQueue:getAttr("toRefreshId"))
                        queue:setAttr("toCfgId", mainQueue:getAttr("toCfgId"))
                        queue:setAttr("toUid", mainQueue:getAttr("toUid"))
                        queue:setAttr("toBelongAid", mainQueue:getAttr("toBelongAid"))
                        queue:setAttr("toX", mainQueue:getAttr("toX"))
                        queue:setAttr("toY", mainQueue:getAttr("toY"))
                    end
                end
            end
        end
    end
    return next(changeQidMap) and changeQidMap
end

function queueCallbackLogic:reorganize(mainQueue, addQueue)
    if not mainQueue or not addQueue or mainQueue:getUid() ~= addQueue:getUid() then
        return
    end
    gLog.i("queueCallbackLogic:reorganize", mainQueue:getId(), addQueue:getId())
    local addArmyCellList = addQueue:getAttr("army")
    local addArmyMap = {}
    for _, cell in pairs(addArmyCellList) do
        addArmyMap[cell.id] = (addArmyMap[cell.id] or 0) + cell.num
    end
    mainQueue:addArmy(addArmyMap)
    addQueue:setAttr("army", {})
    local newMaxMassNum = addQueue:getAttr("maxMassNum") or 0
    local oldMaxMassNum = mainQueue:getAttr("maxMassNum") or 0
    local types
    if newMaxMassNum > oldMaxMassNum then
        mainQueue:setAttr("maxMassNum", newMaxMassNum)
        types = 1
    else
        types = 0
    end
    queueUtils:writeOccupyLog(addQueue:getId(), addQueue:getUid(), addQueue:getAttr("toId"), addQueue:getAttr("toMapType"), types, 1) -- 入驻日志
    -- 发送英雄遣返邮件
    local heroList = addQueue:getHeroIdList()
    if heroList and next(heroList) then
        queueUtils:sendHeroReturnMail(addQueue:getUid(), heroList)
    end
    -- 发送宠物遣返邮件
    local petId = addQueue:getPetId()
    if petId then
        queueUtils:sendPetReturnMail(addQueue:getUid(), petId)
    end
    self:returnQueue(addQueue)
    queueCallbackLogic:onUpdateQueue(mainQueue)
end

function queueCallbackLogic:refreshCollMineTime(toId, skipQidMap)
    gLog.i("queueCallbackLogic:refreshCollMineTime toId, skipQidMap =", toId, skipQidMap)
    --local toX, toY = svrFunc.getXYFromMapObjId(toId)
    local sq = self:getSkynetQueue(toId)
    sq(function()
        local collQueueList = queueCallbackLogic:getOccupyQueue(toId)
        if skipQidMap then
            -- 去除指定队列
            local collQueueListTmp = {}
            for _, collQueue in pairs(collQueueList) do
                if not skipQidMap[collQueue:getId()] then
                    table.insert(collQueueListTmp, collQueue)
                end
            end
            collQueueList = collQueueListTmp
        end
        if collQueueList and next(collQueueList) then
            local collTimeSpanMap = queueUtils:calCollMineTimeSpan(toId, collQueueList)
            local curTime = svrFunc.systemTime()
            for _, collQueue in pairs(collQueueList) do
                local collTimeSpanInfo = collTimeSpanMap[collQueue:getUid()]
                local collTimeSpan = collTimeSpanInfo and collTimeSpanInfo.timeSpan
                gLog.d("queueUtils:refreshCollMineTime id =", collQueue:getId())
                gLog.dump(collTimeSpan, "queueUtils:refreshCollMineTime collTimeSpan", 9)
                collQueue:updateCollTimeSpan(collTimeSpan)
                queueCallbackLogic:onUpdateQueue(collQueue)
            end
        end
    end)
end

---------------------------------------- 队列状态变更 end ------------------------------------------

-- 获取串行队列
function queueCallbackLogic:getSkynetQueue(mapKey)
    gLog.d("queueCallbackLogic:getSkynetQueue mapKey =", mapKey)
    if not self.sq[mapKey] then
        self.sq[mapKey] = skynetQueue()
    end
    return self.sq[mapKey]
end

return queueCallbackLogic
