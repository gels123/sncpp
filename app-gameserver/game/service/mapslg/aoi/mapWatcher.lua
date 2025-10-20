--[[
-- 地图观察者 
--]]
local interaction = require "interaction"
local mapWatcher = class("mapWatcher")

function mapWatcher:ctor(playerid)
	assert(playerid)
	
	self.playerid = playerid
	self.x = nil
	self.y = nil
	self.lv = nil
	self.kid = nil -- 观察者所在服务器ID
	self.viewgrid = {}
end

function mapWatcher:get_key()
	return self.playerid
end

function mapWatcher:get_address()
	return self.address
end

function mapWatcher:get_position()
	return self.x, self.y, self.lv
end

function mapWatcher:set_position(x, y, lv, kid, ispost)
	if self.lv ~= lv or self.kid ~= kid or self.ispost ~= ispost then
		self.viewgrid = {}
	end
	self.x, self.y, self.lv, self.kid, self.ispost = x, y, lv, kid, ispost
end

function mapWatcher:get_serverid()
	return self.kid
end

-- 增量格子
function mapWatcher:judge_viewgrid(grids)
	local delgrids = {}
	for key,_ in pairs(self.viewgrid) do
		if not grids[key] then
			table.insert(delgrids, key)
			self.viewgrid[key] = nil
		end
	end
	for key,_ in pairs(grids) do
		if self.viewgrid[key] then
			grids[key] = nil
		else
			self.viewgrid[key] = true
		end
	end
	return grids, delgrids
end

function mapWatcher:send_message(...)
	local mapCenter = require("mapCenter"):shareInstance()
	interaction.send(self.address, mapCenter.MAP_REMOTE, "send2client", ...)
end

return mapWatcher