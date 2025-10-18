--[[
	关联表
	用于管理多对多的关联关系
	可以对key和value进行高效(相较于for循环查询)查询
	支持双向查询，即通过value1检索value2，以及通过value2检索value1
]]
local relevanceTable = class "relevanceTable"

--[[
	needCount 需要进行元素数量统计
	noNeedReverse 不需要双向查询，仅支持通过value1检索value2
]]
function relevanceTable:ctor(needCount, noNeedReverse)
	self.needCount = needCount
	self.noNeedReverse = noNeedReverse
	self.relevance = {} -- 正向关联
	if not self.noNeedReverse then
		self.reverse = {} -- 反向关联
	end
	if self.needCount then
		self.count = {}
	end
end

--[[
	plus 1表示加一 -1表示减一 0表示清空
]]
local function updateCount(self, rTable, value1, plus)
	if not self.needCount
	 or not rTable or not value1 or not plus then
		return
	end
	self.count[rTable] = self.count[rTable] or {}
	if 0 == plus then
		self.count[rTable][value1] = nil
	else
		self.count[rTable][value1] = (self.count[rTable][value1] or 0) + plus
	end
end

local function doSet(self, rTable, value1, value2, weight)
	rTable[value1] = rTable[value1] or {}
	if rTable[value1][value2] then
		return false -- 已存在关联
	else
		rTable[value1][value2] = weight or true
		updateCount(self, rTable, value1, 1)
		return true
	end
end

local function doRemove(self, rTable, value1, value2)
	local ret
	if rTable[value1] then
		if value2 then
			if not rTable[value1][value2] then
				return false -- 不存在关联
			end
			ret = rTable[value1][value2]
			rTable[value1][value2] = nil
			if not next(rTable[value1]) then
				rTable[value1] = nil
				updateCount(self, rTable, value1, 0)
			else
				updateCount(self, rTable, value1, -1)
			end
		else
			ret = rTable[value1]
			rTable[value1] = nil
			updateCount(self, rTable, value1, 0)
		end
	else
		return false -- 不存在关联
	end
	
	return ret
end



--[[
	设置关联
	weight 权重，可选
	return bool -- 是否为新增
]]
function relevanceTable:set(value1, value2, weight)
	if not value1 or not value2 then
		return
	end
	if not self.noNeedReverse then
		doSet(self, self.reverse, value2, value1, weight)
	end
	return doSet(self, self.relevance, value1, value2, weight)
end

--[[
	移除关联
	value1，value2 全部有传值则删除指定关联，若只有单个有传值则删除传值一方的所有关联
	return {
		[value1] = {
			[value2] = weight,
			...
		}
	} -- 删前是否有值
]]
function relevanceTable:remove(value1, value2)
	if not value1 and not value2 then
		return
	end
	if value1 and value2 then
		if not self.noNeedReverse then
			doRemove(self, self.reverse, value2, value1)
		end
		local rmWeight = doRemove(self, self.relevance, value1, value2)
		if rmWeight then
			return {
				[value1] = {
					[value2] = rmWeight
				}
			}
		else
			return
		end
	elseif value1 then
		local value2Map = self:get(value1)
		if not value2Map then
			return
		end
		for rValue2, _ in pairs(value2Map) do
			doRemove(self, self.reverse, rValue2, value1)
		end
		local rmMap = doRemove(self, self.relevance, value1)
		return {
			[value1] = rmMap
		}
	elseif value2 then
		local value1Map = self:get(nil, value2)
		if not value1Map then
			return
		end
		local rmMap = {}
		for rValue1, _ in pairs(value1Map) do
			local rmWeight = doRemove(self, self.relevance, rValue1, value2)
			if rmWeight then
				rmMap[rValue1] = rmMap[rValue1] or {}
				rmMap[rValue1][value2] = rmWeight
			end
		end
		doRemove(self, self.reverse, value2)
		return rmMap
	end
end

--[[
	检索关联值
	value1, value2二选一
	needClone 是否需要返回拷贝以供调用方进行修改
	return {
		[value] = weight or true,
		...
	}
]]
function relevanceTable:get(value1, value2, needClone)
	if value1 then
		return needClone and clone(self.relevance[value1]) or self.relevance[value1]
	elseif value2 then
		return needClone and clone(self.reverse[value2]) or self.reverse[value2]
	else
		svrFunc.exception("queueNotifyMgr:getQid2MapIds qid, mapId is nil")
	end
end

-- --[[
-- 	value1, value2 二选一
-- 	limit num 按权重顺序返回多少条
-- 	desc bool 可选 true倒序 false顺序
-- 	startWeight num 可选 起始权重，判断大小时不包含等于startWeight
-- 	return {
-- 		[value] = weight,
-- 		...
-- 	}
-- ]]
-- function relevanceTable:limitGet(value1, value2, limit, startWeight, desc)
-- 	if not self.needWeight  then
-- 		return
-- 	end
-- 	-- 总结果条数小于limit则不需要过滤，直接全部返回（默认不拷贝）
-- 	if not startWeight and self:count(value1, value2) <= limit then
-- 		return self:get(value1, value2)
-- 	end
-- 	local retNum = 0
-- 	local ret = {}
-- 	local sIndex, eIndex, inc
-- 	local lastWeight
-- 	if desc then
-- 		-- 倒序
-- 		sIndex, eIndex, inc = #self.sortWeight, 1, -1
-- 	else
-- 		-- 顺序
-- 		sIndex, eIndex, inc = 1, #self.sortWeight, 1
-- 	end
-- 	for index = sIndex, eIndex, inc do
-- 		local weightCell = self.sortWeight[index]
-- 		-- 判断权值
-- 		if not startWeight
-- 		 or desc and (weightCell.weight < startWeight)
-- 		 or (weightCell.weight > startWeight) then
-- 		 	-- 判断是否为需要的关联值
-- 		 	if value1 then
-- 				if value1 == weightCell.value1 then
-- 					ret[value2] = weightCell.weight
-- 				end
-- 			elseif value2 then
-- 				if value2 == weightCell.value2 then
-- 					ret[value1] = weightCell.weight
-- 				end
-- 			end
-- 			retNum = retNum + 1
-- 			-- 判断返回条数
-- 			if retNum >= limit then
-- 				lastWeight = weightCell.weight
-- 				break
-- 			end
-- 		end
-- 	end
-- 	return ret, lastWeight
-- end




--[[
	检查是否存在关联
	value2 可选，为nil则只检查是否存在value1
	return bool
]]
function relevanceTable:check(value1, value2)
	if value1 and value2 then
		return self.relevance[value1] and self.relevance[value1][value2]
	elseif value1 then
		return self.relevance[value1] and next(self.relevance[value1])
	else
		return false
	end
end

--[[
	获取关联元素个数
	value1, value2二选一
]]
function relevanceTable:getCount(value1, value2)
	local countTbl
	if value1 then
		countTbl = self.relevance
	elseif value2 then
		countTbl = self.reverse
	else
		return 0
	end
	return self.count and self.count[countTbl] and self.count[countTbl][value1 or value2] or 0
end


return relevanceTable