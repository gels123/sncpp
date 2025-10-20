--[[
	队列格子单元
--]]
local skynet = require("skynet")
local queueGridCell = class("queueGridCell")

function queueGridCell:ctor(key)
	assert(key)
	self.key = key          	--key
	self.watchers = {} 		--观察者
	self.queues = {} 	    	--队列对象数据
end

function queueGridCell:get_key()
	return self.key
end

function queueGridCell:get_watchers()
	return self.watchers
end

function queueGridCell:add_watcher(watcher)
	gLog.d("queueGridCell:add_watcher key=", self.key, watcher:get_key())
	self.watchers[watcher:get_key()] = watcher
end

function queueGridCell:remove_watcher(watcher)
	gLog.d("queueGridCell:remove_watcher key=", self.key, watcher:get_key())
	self.watchers[watcher:get_key()] = nil
end

function queueGridCell:getQueue()
	return self.queues
end

function queueGridCell:addQueue(queue)
	self.queues[queue:getId()] = queue
end

function queueGridCell:removeQueue(queue)
	self.queues[queue:getId()] = nil
end

return queueGridCell