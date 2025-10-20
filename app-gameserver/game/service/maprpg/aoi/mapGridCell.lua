--[[
	单位格子
--]]
local mapGridCell = class("mapGridCell")

function mapGridCell:ctor(key)
	assert(key)
	self.key = key          --key
	self.watchers = {} 		--观察者
	self.objects = {} 	    --地图活物数据
end

function mapGridCell:get_key()
	return self.key
end

function mapGridCell:add_watcher(watcher)
	self.watchers[watcher:get_key()] = watcher
end

function mapGridCell:remove_watcher(watcher)
	self.watchers[watcher:get_key()] = nil
end

function mapGridCell:add_object(obj)
	self.objects[obj:get_objectid()] = obj
end

function mapGridCell:remove_object(obj)
	self.objects[obj:get_objectid()] = nil
end

function mapGridCell:get_watchers()
	return self.watchers
end

function mapGridCell:pack_message_data(slv, ispost)
	local ret = {}
	for _, obj in pairs(self.objects) do
		local data = obj:pack_message_data()
		if not ispost and slv >= 3 and data.type == mapConf.object_type.commandpost and not data.isAct then

		else
			table.insert(ret, data)
		end
	end
	return ret
end

function mapGridCell:pack_objid_message(ret)
	for _, obj in pairs(self.objects) do
		table.insert(ret, obj:get_key())
	end
end

return mapGridCell