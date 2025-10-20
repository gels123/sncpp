--[[
    测试: 排队削峰-漏桶算法
]]
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()	
gLog.i("=====testLeakyBucket begin")
print("=====testLeakyBucket begin")

	local leakyBucket = require("leakyBucket").new()

	-- 流入一滴水
	local ok = leakyBucket:inputWater()
	if not ok then
		return --桶满了, 业务繁忙
	end

	-- 流出一滴水, 添加一滴当前流出量
	local ok = leakyBucket:outputWater()
	if ok then
		return --流量满了
	end
	pcall(function ()
		--处理业务
	end)
	-- 任务完成减少流量
	leakyBucket:outSuccess()


gLog.i("=====testLeakyBucket end")
print("=====testLeakyBucket end")
end,svrFunc.exception)