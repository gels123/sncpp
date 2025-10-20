--[[
	地图定时器管理器
]]
local mapConf = require("mapConf")
local mapCenter = require("mapCenter"):shareInstance()
local mapTimerMgr = class("mapTimerMgr")

--[[
	地图对象定时器配置 最后确定子表的参数只有timerType的话直接把表改为字段值
]]
mapTimerMgr.timerCfg = {
	[mapConf.object_type.monster] = {
		pack = "pack",
		deadTime = "deadTime",
	},
	[mapConf.object_type.chest] = {
		pack = "pack",
		deadTime = "deadTime",
	},
	[mapConf.object_type.boss] = {
		pack = "pack",
	},
	[mapConf.object_type.playercity] = {
		pack = "pack",
		shieldover = "shieldover",
		landshieldover = "landshieldover",
		recoverTime = "recoverTime",
		skintime = "skintime",
		ownTime = "ownTime",
		burntime = "burntime",
	},
	[mapConf.object_type.buildmine] = {
		pack = "pack",
		defenderCdTime = "defenderCdTime",
		shieldover = "shieldover",
	},
	[mapConf.object_type.fortress] = {
		pack = "pack",
		ownTime = "ownTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
	},
	[mapConf.object_type.checkpoint] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		annouceTime = "annouceTime",
	},
	[mapConf.object_type.wharf] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		annouceTime = "annouceTime",
	},
	[mapConf.object_type.city] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		skintime = "skintime",
		annouceTime = "annouceTime",
	},
	[mapConf.object_type.commandpost] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		annouceTime = "annouceTime",
	},
	[mapConf.object_type.station] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		annouceTime = "annouceTime",
	},
	[mapConf.object_type.mill] = {
		pack = "pack",
		buildTime = "buildTime",
		recoverTime = "recoverTime",
		defenderCdTime = "defenderCdTime",
		annouceTime = "annouceTime",
	},
}

-- 
function mapTimerMgr:ctor()
	--[[
		地图对象定时器ID表
		{
			[objectid] = {
				[timerType] = timerId,
				...
			},
			...
		}
	]]
	self.timersMap = {}
	--[[
		地图对象缓存数据定时器ID表
	]]
	self.cacheMap = {}
end

-- 初始化
function mapTimerMgr:init()

end

function mapTimerMgr:addTimer(fun, endtime, param, repeats)
	return mapCenter.mytimer:schedule(fun, endtime, param, repeats)
end

function mapTimerMgr:addRepeatTimer(fun, interval, param)
	return mapCenter.mytimer:repeatSchedule(fun, interval, param)
end

function mapTimerMgr:removeTimer(timerId)
	mapCenter.mytimer:stop(timerId)
end

-- 新增地图对象定时器
function mapTimerMgr:addObjTimer(obj)
	if not obj then
		return
	end
	local colCfg = self.timerCfg[obj:getMapType()]
	if colCfg then
		for k,v in pairs(colCfg) do
			local endTime = obj:get_field(k)
			if endTime and endTime > 0 then
				self:doUpdate(obj:get_objectid(), v, endTime)
			end
		end
	end
end

-- 删除地图对象定时器
function mapTimerMgr:removeObjTimer(objectid, timerType)
	local hasTimer = false
	local timerTypeMap = self.timersMap[objectid]
	if timerTypeMap then
		-- gLog.dump(timerTypeMap, "mapTimerMgr:removeObjTimer timerTypeMap", 10)
		local itrMap = clone(timerTypeMap)
		for timerTypeFor, timerId in pairs(itrMap) do
			if not timerType or timerType == timerTypeFor then
				if timerType ~= "pack" then
					gLog.i("mapTimerMgr:removeObjTimer objectid, timerId, timerType =", objectid, timerId, timerType)
				end
				self:removeTimer(timerId)
				self.timersMap[objectid][timerTypeFor] = nil
				hasTimer = true
			end
		end
	end
	if self.timersMap[objectid] and not next(self.timersMap[objectid]) then
		self.timersMap[objectid] = nil
	end
	return hasTimer
end

function mapTimerMgr:doUpdate(objectid, timerType, endTime)
	if not objectid or not timerType then
		return
	end
	local timerId = self.timersMap[objectid] and self.timersMap[objectid][timerType]
	if not endTime or endTime <= 0 then
		if timerId then
			gLog.i("mapTimerMgr:doUpdate 1=", timerType, objectid, endTime, timerId)
			-- 删除现有计时器
			mapCenter.mytimer:stop(timerId)
			self.timersMap[objectid][timerType] = nil
			if not next(self.timersMap[objectid]) then
				self.timersMap[objectid] = nil
			end
		end
	else
		if timerType ~= "pack" then
			gLog.i("mapTimerMgr:doUpdate 2=", timerType, objectid, endTime, timerId)
		end
		if timerId then
			-- 更新计时器回调时间
			mapCenter.mytimer:reset(timerId, endTime)
		else
			-- 新增计时器
			timerId = self:addTimer(handler(mapCenter.mapObjectMgr, mapCenter.mapObjectMgr.timerCallback), endTime, {id = objectid, timerType = timerType})
			if not self.timersMap[objectid] then
				self.timersMap[objectid] = {}
			end
			self.timersMap[objectid][timerType] = timerId
		end
	end
end

function mapTimerMgr:isTimerKey(mapType, key)
	return self.timerCfg[mapType] and self.timerCfg[mapType][key]
end

return mapTimerMgr