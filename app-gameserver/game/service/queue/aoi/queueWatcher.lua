--[[
	队列观察者 
--]]
local queueWatcher = class("queueWatcher")
local queueCenter = require("queueCenter"):shareInstance()

function queueWatcher:ctor(playerid, address)
	self.playerid = playerid
	self.address = address

	self.x = nil
	self.y = nil
	self.lv = nil
	self.serverid = nil -- 观察者所在服务器ID
	self.viewQueues = {}
end

function queueWatcher:get_key()
	return self.playerid
end

function queueWatcher:get_address()
	return self.address
end

function queueWatcher:get_position()
	return self.x, self.y, self.lv, self.serverid
end

function queueWatcher:set_position(x, y, lv, serverid)
	if not x or not y or not lv or not serverid then
		gLog.e("queueWatcher:set_position error", x, y, lv, serverid)
		return
	end
	if self.lv ~= lv or self.serverid ~= serverid then
		self.viewQueues = {}
	end
	self.x, self.y, self.lv, self.serverid = x, y, lv, serverid
end

function queueWatcher:get_serverid()
	return self.serverid
end

-- 增量队列
function queueWatcher:judge_viewqueue(grids, playerid)
	gLog.d("queueWatcher:judge_viewqueue begin=", playerid, "grids=", table.keys(grids), "oldview=", table.keys(self.viewQueues))
	local addQueues, delQueues = {}, {}

	local ret = {}
	for key,grid in pairs(grids) do
		local queues = grid:getQueue()
		if next(queues) then
			for qid,queue in pairs(queues) do
				if queue:getUid() ~= playerid then
					ret[qid] = queue:packData()
				end
			end
		end
	end
	for qid,v in pairs(ret) do
		if not self.viewQueues[qid] then
			addQueues[qid] = v
		end
	end
	for qid,v in pairs(self.viewQueues) do
		if not ret[qid] then
			table.insert(delQueues, qid)
		end
	end
	self.viewQueues = ret
	--gLog.d("queueWatcher:judge_viewqueue end=", playerid, table.keys(ret), "addQueues=", table.keys(addQueues), "delQueues=", delQueues)

	return addQueues, delQueues
end

return queueWatcher