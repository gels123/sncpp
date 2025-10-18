local closureQueue = class("closureQueue")
local respondCtrl = require("respondCtrl")
local skynet = require "skynet"

function closureQueue:ctor()
	self.queue = {}
	self.lockTag = {}
end

function closureQueue:lock(id, fun, req)
	if not self.lockTag[id] then
		self.lockTag[id] = false
	end
	if not self.lockTag[id] then
		self.lockTag[id] = true
		respondCtrl.respondtocmd(fun and fun(req))
	else
		if not self.queue[id] then
			self.queue[id] = {}
		end
		local responseClosure = {}
        responseClosure.responseClosure = respondCtrl.createCmdResponseClosure()
        responseClosure.req = req
        responseClosure.fun = fun
        table.insert(self.queue[id], responseClosure)
	end
end

function closureQueue:unlock(id)
	local responseClosure
	if self.queue[id] and #self.queue[id] > 0 then
		responseClosure = table.remove(self.queue[id], 1)
	end
	if not self.queue[id] or #self.queue[id] == 0 then
		self.queue[id] = nil
		self.lockTag[id] = nil
	end
	if responseClosure then
		responseClosure.responseClosure(true, responseClosure.fun and responseClosure.fun(responseClosure.req))
	end
end

return closureQueue