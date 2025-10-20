--[[
    玩家代理池管理
--]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local playerDataLib = require("playerDataLib")
local agentPoolCellC = require("agentPoolCell")
local agentPoolCenter = require("agentPoolCenter"):shareInstance()
local agentPoolMgr = class("agentPoolMgr")

-- 构造
function agentPoolMgr:ctor()
	-- 玩家代理池
	self.agentPool = {}
	-- 玩家代理池数量
	self.agentNum = 0
	-- 热更参数
	self.hotFixes = nil
end

-- 获取玩家代理池
function agentPoolMgr:getAgentPool()
	return self.agentPool
end

-- 获取所有在线的玩家UID
function agentPoolMgr:getOnlinePlayers()
	local ret = {}
	for uid, poolCell in pairs(self.agentPool) do
		if poolCell:getOnline() then
			table.insert(ret, uid)
		end
	end
	return ret
end

-- 获取所有在线的玩家UID人数
function agentPoolMgr:getOnlinePlayersNum()
	local num = 0
	for uid, poolCell in pairs(self.agentPool) do
		if poolCell:getOnline() then
			num = num + 1
		end
	end
	return num
end

-- 获取所有玩家UID
function agentPoolMgr:getAllPlayers()
	local ret = {}
	for uid, poolCell in pairs(self.agentPool) do
		table.insert(ret, uid)
	end
	return ret
end

-- 获取Agent总数
function agentPoolMgr:getAgentTotalNum()
	return self.agentNum
end

-- 查找Agent
function agentPoolMgr:queryAgent(uid)
	return self.agentPool[uid]
end

-- 移除Agent
function agentPoolMgr:removeAgent(uid)
	if self.agentPool[uid] then
		self.agentPool[uid] = nil
		self.agentNum = self.agentNum - 1
	end
end

-- 开启一个玩家代理
function agentPoolMgr:startAgent(uid, subid, kid, isNew, version, plateform, model, addr)
	uid = tonumber(uid)
	-- 检查玩家UID
	if not uid or uid <= 0 then
		gLog.e("agentPoolMgr:startAgent error1: uid is invalid!", uid, subid, kid)
		return
	end
	-- 检查玩家账号是否存在
	local poolCell = self.agentPool[uid]
	if not poolCell then
		-- 检查玩家账号是否存在, 迁服成功后kid变更, 不会再拉起agent
		local kid2 = playerDataLib:getKidOfUid(agentPoolCenter.kid, uid) or kid
		if kid2 ~= kid or kid2 ~= agentPoolCenter.kid then
	 		gLog.e("agentPoolMgr:startAgent error2: uid is not exist!", uid, subid, kid, kid2)
	 		return
	 	end
		-- 创建agent
		gLog.i("agentPoolMgr:startAgent new poolCell, uid=", uid, subid, kid)
		poolCell = agentPoolCellC.new()
		self.agentPool[uid] = poolCell
		self.agentNum = self.agentNum + 1
		-- 启动
		local xpcallok, ok = xpcall(poolCell.login, svrFunc.exception, poolCell, uid, subid, kid, isNew, version, plateform, model, addr)
		if not xpcallok or not ok then
			gLog.e("agentPoolMgr:startAgent error3: login failed!", uid, subid, kid)
			skynet.timeout(1000, function()
				-- 异常处理, 10s防止反复重登导致宕机
				local agent = poolCell:getAgent()
				gLog.w("agentPoolMgr:startAgent fix=", uid, agent)
				if not poolCell:isWork() then
					if agent then
						skynet.send(agent, "lua", "free")
					end
					self:removeAgent(uid)
				end
			end)
			return
		end
	end
	return poolCell
end

-- 计时器回调
function agentPoolMgr:timerCallback(data)
	if dbconf.DEBUG then
		gLog.d("agentPoolMgr:timerCallback data=", table2string(data))
	end
	local uid, timerType = data.id, data.timerType
	if agentPoolCenter.timerMgr:hasTimer(uid, timerType) then
		if timerType == gAgentPoolTimerType.free then --释放agent
			local poolCell = self.agentPool[uid]
			if poolCell then
				local ok = poolCell:safeFree()
				gLog.i("agentPoolMgr:timerCallback safeFree end=", uid, "ok=", ok)
			end
		else
			gLog.w("agentPoolMgr:timerCallback ignore", uid, timerType)
		end
	else
		gLog.w("agentPoolMgr:timerCallback repeat", uid, timerType)
	end
end

-- 停止服务
function agentPoolMgr:stop()
	-- 缩短释放agent时间
	gAgentFreeTime = 2
	--
	if next(self.agentPool) then
		for uid, poolCell in pairs(self.agentPool) do
			skynet.fork(function()
				if poolCell:getOnline() then
					poolCell:afk(4)
				else
					agentPoolCenter.timerMgr:updateTimer(uid, gAgentPoolTimerType.free, 0)
					poolCell:safeFree()
				end
			end)
		end
	end
end

--[[
	热更玩家agent
	@script 热更脚本名
]]
function agentPoolMgr:hotFix(script)
	self.hotFixes = {
		script = script,
	}
	-- 将现有agent全部热更
	if next(self.agentPool) then
		for uid, poolCell in pairs(self.agentPool) do
			poolCell:hotFix()
		end
	end
end

return agentPoolMgr