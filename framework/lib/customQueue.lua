--
-- Date: 2015-10-07 20:41:41
--
local skynet = require "skynet"
local coroutine = coroutine
local xpcall = xpcall
local table = table

local customQueue = {}

function customQueue.queue()
	local current_thread
	local ref = 0
	local thread_queue = {}
	return function(needQueue, f, ...)
		--if not needQueue and #thread_queue == 0 then
		if not needQueue then
			local ok, err = xpcall(f, svrFunc.exception, ...)
			assert(ok,err)
			return
		end

		local thread = coroutine.running()
		if current_thread and current_thread ~= thread then
			table.insert(thread_queue, thread)
			skynet.wait()
			assert(ref == 0)	-- current_thread == thread
		end
		current_thread = thread

		if needQueue then
			ref = ref + 1
			local ok, err = xpcall(f, svrFunc.exception, ...)
			ref = ref - 1
			if ref == 0 then
				current_thread = table.remove(thread_queue,1)
				if current_thread then
					skynet.wakeup(current_thread)
				end
			end
			assert(ok,err)
		else
			current_thread = table.remove(thread_queue,1)
			if current_thread then
				skynet.wakeup(current_thread)
			end
		end
	end
end

return customQueue.queue
