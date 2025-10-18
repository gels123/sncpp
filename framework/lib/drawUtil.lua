--[[
	抽奖工具
]]
local drawUtil = {}

--[[
	根据权重抽取
	配置示例：
	{
		[1] = {reward= {100307, 5, }, probability=200, },
	}
]]
function drawUtil.drawWithProbability(cfg)
	local reward = {}
	local index = drawUtil.getIndexForReward(cfg)
	if cfg[index] then
		reward = svrFunc.tableFormat(cfg[index].reward, { "id", "count" })
	end
	return index,reward
end

--[[
	完全随机抽取
	配置示例：
	{
		[1] = {reward= {100307, 5, }, },
	}
]]
function drawUtil.drawRandom(cfg)
	local reward = {}
	local index = svrFunc.random(1, #cfg)
	reward = svrFunc.tableFormat(cfg[index].reward, { "id", "count" })
	return index,reward
end

--[[
	只随机抽取配置带标记的物品
	{
		[1] = {reward= {100307, 5, }, mark=1, },
		[2] = {reward= {100307, 5, }, mark=0, },
		[3] = {reward= {100307, 5, }, mark=0, },
		[4] = {reward= {100307, 5, }, mark=1, },
	}
]]
function drawUtil.drawRandomWithMark(cfg)
	local reward = {}
	local newCfg = {}
	for index,data in pairs(cfg) do
		if data.mark == 1 then
			table.insert(newCfg,data)
			newCfg[#newCfg].index = index
		end
	end
	local index = svrFunc.random(1, #newCfg)
	reward = svrFunc.tableFormat(newCfg[index].reward, { "id", "count" })
	local trueIndex = newCfg[index].index
	return trueIndex,reward
end

--是否抽取出奖励(rate为万分比)
function drawUtil.isGetReward(cfg,rate,index)
	local isGet = false
	local reward = {}
	isGet = svrFunc.checkRandom(rate/10000)
	if isGet then
		if index then
			reward = svrFunc.tableFormat(cfg[index].reward, { "id", "count" })
		else
			reward = svrFunc.tableFormat(cfg.reward, { "id", "count" })
		end
	end
	return isGet,reward
end

--从配置表中根据权重获取一个索引
function drawUtil.getIndexForReward(cfg)
	local totalRate = 0
    for _,data in pairs(cfg) do
        totalRate = totalRate + data.probability
    end
    if totalRate > 0 then
        local randNum = svrFunc.random(1, totalRate)
        local curTotalRate = 0
        for index,data in pairs(cfg) do
            curTotalRate = curTotalRate + data.probability
            if randNum <= curTotalRate then
                return index
            end
        end
    end
	return 0
end

return drawUtil