--[[
	队列定时器管理器
]]
local skynet = require("skynet")
local queueConf = require("queueConf")
local queueCenter = require("queueCenter"):shareInstance()
local queueTimerMgr = class("queueTimerMgr")

--[[
	队列对象定时器配置 最后确定子表的参数只有timerType的话直接把表改为字段值
]]
queueTimerMgr.timerCfg = queueConf.queueTimerType

-- 
function queueTimerMgr:ctor()
	--[[
		队列对象定时器ID表
		{
			[qid] = {
				[timerType] = timerId,
				...
			},
			...
		}
	]]
	self.timersMap = {}
end

function queueTimerMgr:addTimer(fun, endtime, param, repeats)
	return queueCenter.myTimer:schedule(fun, endtime, param, repeats)
end

function queueTimerMgr:removeTimer(timerId)
	queueCenter.myTimer:stop(timerId)
end

--[[
	增加对象定时器
]]
function queueTimerMgr:addObjTimer(queue)
	if not queue then
		return
	end
	for timerColName, timerType in pairs(self.timerCfg) do
		local endTime = queue:getAttr(timerColName)
		gLog.d("queueTimerMgr:addObjTimer qid=", queue:getId(), timerColName, endTime)
		if endTime and endTime > 0 then
			self:doUpdate(queue:getId(), timerType, endTime)
		end
	end
end

--[[
	更新对象的定时器
]]
function queueTimerMgr:updateObjTimer(queue)
	if not queue then
		return
	end
	local keyMap = queue:popTimerChange()
	if not keyMap then
		return
	end
	for key, _ in pairs(keyMap) do
		local timerType = self.timerCfg[key]
		local endTime = queue:getAttr(key)
		self:doUpdate(queue:getId(), timerType, endTime)
	end
end

function queueTimerMgr:doUpdate(qid, timerType, endTime)
	if not qid or not timerType or not endTime then
		return
	end
	gLog.i("queueTimerMgr:doUpdate qid=", qid, "timerType=", timerType, "endTime=", endTime)
	local timerId = self.timersMap[qid] and self.timersMap[qid][timerType]
	if endTime <= 0 then
		if timerId then
			-- 删除现有计时器
			queueCenter.myTimer:stop(timerId)
			self.timersMap[qid][timerType] = nil
			if not next(self.timersMap[qid]) then
				self.timersMap[qid] = nil
			end
		end
	else
		if timerId then
			-- 更新计时器回调时间
			queueCenter.myTimer:reset(timerId, endTime)
		else
			-- 新增计时器
			timerId = self:addTimer(handler(queueCenter.queueCallbackLogic, queueCenter.queueCallbackLogic.timerCallback), endTime, {id = qid, timerType = timerType})
			gLog.i("queueTimerMgr:doUpdate new timer qid=", qid, "timerType=", timerType, "timerId=", timerId, "endTime=", endTime)
			self.timersMap[qid] = self.timersMap[qid] or {}
			self.timersMap[qid][timerType] = timerId
		end
	end
end

function queueTimerMgr:removeObjTimer(qid, timerType)
	local hasTimer = false
	local timerTypeMap = self.timersMap[qid]
	if timerTypeMap then
		gLog.dump(timerTypeMap, "queueTimerMgr:removeObjTimer timerTypeMap", 10)
		local itrMap = clone(timerTypeMap)
		for timerTypeFor, timerId in pairs(itrMap) do
			if not timerType or timerType == timerTypeFor then
				gLog.i("queueTimerMgr:removeObjTimer qid=", qid, "timerId=", timerId, "timerType=", timerType)
				self:removeTimer(timerId)
				self.timersMap[qid][timerTypeFor] = nil
				hasTimer = true
			end
		end
	end
	if self.timersMap[qid] and not next(self.timersMap[qid]) then
		self.timersMap[qid] = nil
	end
	return hasTimer
end

function queueTimerMgr:hasTimer(qid)
	return self.timersMap[qid] and next(self.timersMap[qid])
end

function queueTimerMgr:isTimerKey(key)
	return self.timerCfg[key]
end

return queueTimerMgr
