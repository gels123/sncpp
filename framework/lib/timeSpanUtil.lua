--
-- User: zw
-- Date: 2016-12-29
-- Desc: 采集时间分段
--
local timeSpanUtil = {}

--[[
timeSpan = {
	{
		time = 3600,
		speed = 1800,
		plus = 500,
	},
	...
}

userTimeSpanMap = {
	[uid] = { timeSpan = timeSpan, startTime = 0, },
	[uid2] = { timeSpan = timeSpan, startTime = 0, },
}
]]

-- 获取时间分段总采集时间
function timeSpanUtil.getTotalCollTime(timeSpan)
	local totalCollTime = 0
	for _, timeSpanItem in ipairs(timeSpan) do
		totalCollTime = totalCollTime + timeSpanItem.time
	end
	return totalCollTime
end

-- 获取时间分段总采集量
function timeSpanUtil.getTotalCollNum(timeSpan)
	local totalCollNum = 0
	for _, timeSpanItem in ipairs(timeSpan) do
		totalCollNum = totalCollNum + timeSpanItem.time * timeSpanItem.speed
	end
	return totalCollNum
end

-- 获取时间分段内某个时刻所属分段
function timeSpanUtil.getSpanItem(timeSpan, startTime, t)
	local currCollTime = t - startTime
	if currCollTime >= 0 then
		local totalCollTime = 0
		for i, timeSpanItem in ipairs(timeSpan) do
			totalCollTime = totalCollTime + timeSpanItem.time
			if svrFunc.getIntPart(currCollTime) < svrFunc.getIntPart(totalCollTime) then
				return timeSpanItem, i
			end
		end
	end
end

-- 获取截止到endTime时刻的采集量
function timeSpanUtil.getCollNum(timeSpan, startTime, endTime)
	local totalCollTime = 0
	local collNum = 0

	for _, timeSpanItem in ipairs(timeSpan) do
		-- 分段采满
		local itemFinishTime = startTime + totalCollTime + timeSpanItem.time
		if itemFinishTime <= endTime then
			collNum = collNum + timeSpanItem.speed * timeSpanItem.time / 3600
			if itemFinishTime == endTime then
				break
			end
		else
			-- 分段未满
			local collTime = endTime - (startTime + totalCollTime)
			if collTime > 0 then
				collNum = collNum + timeSpanItem.speed * collTime / 3600
			end
			break
		end
		totalCollTime = totalCollTime + timeSpanItem.time
	end
	return collNum
end

-- 重新设置截止时刻
function timeSpanUtil.newEndTimeSpan(timeSpan, startTime, endTime)
	local newTimeSpan = {}
	local currCollTime = endTime - startTime
	local totalCollTime = 0
	for _, timeSpanItem in ipairs(timeSpan) do
		totalCollTime = totalCollTime + timeSpanItem.time
		if currCollTime >= totalCollTime then
			table.insert(newTimeSpan, timeSpanItem)
			if currCollTime == totalCollTime then
				break
			end
		else
			local item = {
				time = timeSpanItem.time - (totalCollTime - currCollTime),
				speed = timeSpanItem.speed,
				plus = timeSpanItem.plus,
			}
			table.insert(newTimeSpan, item)
			break
		end
	end
	return newTimeSpan
end

-- 获取采集时间片段的每一段的开始时间点列表
function timeSpanUtil.getSpanTimeList(timeSpan, startTime)
	local spanTimeList = { startTime }
	local spanTime = startTime
	for _, spanItem in ipairs(timeSpan) do
		spanTime = spanTime + spanItem.time
		table.insert(spanTimeList, spanTime)
	end
	-- dump(spanTimeList)
	return spanTimeList
end

-- 合并多个玩家的采集时间片段的所有开始时间点列表
function timeSpanUtil.mergeUserSpanTimeList(userTimeSpanMap)
	local multiSpanTimeList = {}
	local timeMap = {}
	for _, item in pairs(userTimeSpanMap) do
		local spanEndTimeList = timeSpanUtil.getSpanTimeList(item.timeSpan, item.startTime)
		for _, endTime in ipairs(spanEndTimeList) do
			if not timeMap[endTime] then
				timeMap[endTime] = true
				table.insert(multiSpanTimeList, endTime)
			end
		end
	end

	-- 按时间顺序排列
	table.sort(multiSpanTimeList, function(t1, t2)
		return t1 < t2
	end)
	-- dump(multiSpanTimeList)
	return multiSpanTimeList
end

-- 计算多个玩家共同采集的时间分段
function timeSpanUtil.multiBuffTimeSpan(userTimeSpanMap, totalReaminNum)
	local newUserTimeSpanMap = {}
	local multiSpanTimeList = timeSpanUtil.mergeUserSpanTimeList(userTimeSpanMap)

	-- 从后往前遍历，找到一个时刻前所有人采集的数量小于总量。这个时刻的时段内找结束点
	for i = #multiSpanTimeList, 1, -1 do
		local startTime = multiSpanTimeList[i]
		local allUserCollNum = 0
		for _, item in pairs(userTimeSpanMap) do
			allUserCollNum = allUserCollNum + timeSpanUtil.getCollNum(item.timeSpan, item.startTime, startTime)
		end

		if allUserCollNum <= totalReaminNum then
			local remainNum = totalReaminNum - allUserCollNum

			local totalSpeed = 0
			local remainUserMap = {}
			for uid, item in pairs(userTimeSpanMap) do
				-- 获取这时间段里该玩家的采集速度
				local spanItem = timeSpanUtil.getSpanItem(item.timeSpan, item.startTime, startTime)
				if spanItem then
					-- 累加这时段内还在采集的所有玩家的速度总和
					totalSpeed = totalSpeed + spanItem.speed
					remainUserMap[uid] = item
				else
					-- 在这时刻之前已经完成负重的玩家，直接赋值他完整的时间分段
					newUserTimeSpanMap[uid] = item
				end
			end

			if totalSpeed > 0 then
				-- 最后时段内还在采集的所有玩家的剩余时间都一致
				local collTime = math.ceil(remainNum / (totalSpeed / 3600))

				-- 对这些采集到最后一刻的所有玩家重新设置截止时刻
				for uid, item in pairs(remainUserMap) do
					newUserTimeSpanMap[uid] = {
						timeSpan = timeSpanUtil.newEndTimeSpan(item.timeSpan, item.startTime, startTime + collTime),
						startTime = item.startTime,
						queue = item.queue,
					}
				end
			end
			break
		end
	end
	return newUserTimeSpanMap
end

--[[
-- test
local userTimeSpanMap = {
	[1] = {
		startTime = 1487756129,
		timeSpan = {
			{
				plus = 0.0,
				speed = 600000,
				time = 60,
			},
		},
		queue = {},
	},
	[2] = {
		startTime = 1487756149,
		timeSpan = {
			{
				plus = 0.0,
				speed = 1200000,
				time = 30,
			},
		},
		queue = {},
	},
}

local newUserTimeSpanMap = timeSpanUtil.multiBuffTimeSpan(userTimeSpanMap, 10000)
dump(newUserTimeSpanMap, "timeSpanUtil.test", 10)
]]

return timeSpanUtil
