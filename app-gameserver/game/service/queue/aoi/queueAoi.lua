--[[
	队列aoi
--]]
local queueGridCellC = require "queueGridCell"
local queueConf = require "queueConf"
local mapUtils = require "mapUtils"
local queueCenter = require("queueCenter"):shareInstance()
local queueAoi = class("queueAoi")

-- 6 3 7
-- 2 9 4
-- 5 1 8
--方向偏移值
local deltaXY = {
	mapUtils.get_coord_id(0, -1),
	mapUtils.get_coord_id(-1, 0),
	mapUtils.get_coord_id(0, 1),
	mapUtils.get_coord_id(1, 0),
	mapUtils.get_coord_id(-1, -1),
	mapUtils.get_coord_id(-1, 1),
	mapUtils.get_coord_id(1, 1),
	mapUtils.get_coord_id(1, -1),
	mapUtils.get_coord_id(0, 0),
}

function queueAoi:ctor(width, height, conf)
	-- gLog.d("queueAoi:ctor", width, height, table2string(conf))
	assert(width and height and conf and conf.offset and type(conf.queueTypes) == "table")
	self.width = width
	self.height = height
	self.conf = conf
	self.grids = {} 				--格子

	-- 队列经过的格子关联
	self.queueGridRef = {}

	-- 初始化
	self:init()
end

-- 初始化
function queueAoi:init()
	local nx = math.ceil(self.width / self.conf.offset)
	local ny = math.ceil(self.height / self.conf.offset)
	for x = 1, nx do
		for y = 1, ny do
			local key = mapUtils.get_coord_id(x, y)
			self.grids[key] = queueGridCellC.new(key)
		end		
	end
end

function queueAoi:get_grid_key(x, y)
	return mapUtils.get_coord_id(self:to_grid_xy(x, y))
end

function queueAoi:to_grid_xy(x, y)
	return math.ceil(x / self.conf.offset), math.ceil(y / self.conf.offset)
end

function queueAoi:to_world_xy(x, y)
	return (x - 1) * self.conf.offset + 1, (y - 1) * self.conf.offset + 1
end

function queueAoi:get_offset()
	return self.conf.offset
end

function queueAoi:get_width()
	return self.width
end

function queueAoi:get_height()
	return self.height
end

function queueAoi:get_grid(x, y)
	local key = self:get_grid_key(x, y)
	return self.grids[key]
end

--遍历九宫格
function queueAoi:walk_grids(x, y, func)
	local key = self:get_grid_key(x, y)
	for _, v in pairs(deltaXY) do
		local grid = self.grids[key + v]
		if grid then
			func(grid)
		end
	end
end

--获取观察者观察的所有队列
function queueAoi:getWatcherQueues(watcher, playerid)
	local grids = {}
	local x, y = watcher:get_position()
	self:walk_grids(x, y, function(grid)
		grids[grid:get_key()] = grid
	end)
	return watcher:judge_viewqueue(grids, playerid)
end

function queueAoi:get_grid(x, y)
	local key = self:get_grid_key(x, y)
	return self.grids[key]
end

-- 增加队列
function queueAoi:addQueue(queue, isInit)
	local qid, queueType, status = queue:getId(), queue:getQueueType(), queue:getStatus()
	gLog.d("queueAoi:addQueue enter=", qid, queueType, status)
	if self.queueGridRef[qid] then
		gLog.e("queueAoi:addQueue error1: qid=", qid, queueType, status)
		self:removeQueue(queue)
	end
	local ret = {}
	if queueConf.queueStatus.moving == status then
		local railway_queue_aoi = get_static_config().railway_queue_aoi
		local path = queue:getAttr("moveTimeSpan").path or {}
		for i=1,#path-1 do
			if path[i].railway then
				local id1, id2 = mapUtils.get_coord_id(path[i].x, path[i].y), mapUtils.get_coord_id(path[i+1].x, path[i+1].y)
				local tmpkey = id1 > id2 and string.format("%d_%d", id2, id1) or string.format("%d_%d", id1, id2)
				if railway_queue_aoi[tmpkey] then
					for _,key in pairs(railway_queue_aoi[tmpkey]) do
						if not self.grids[key] then
							gLog.e("queueAoi:addQueue error1", id1, id2, tmpkey)
							break
						else
							ret[key] = self.grids[key]
						end
					end
				else
					gLog.e("queueAoi:addQueue error2", id1, id2, tmpkey)
				end
			else
				local gx0, gy0 = self:to_grid_xy(path[i].x, path[i].y)
				local gx1, gy1 = self:to_grid_xy(path[i+1].x, path[i+1].y)
				self:lineThroughGrids(ret, gx0, gy0, gx1, gy1)
			end
		end
		--gLog.d("queueAoi:addQueue qid=", qid, "offset=", self.conf.offset, "ret=", table.keys(ret))
	elseif queueConf.queueStatus.staying == status or queueConf.queueStatus.occupying == status then
		local key = self:get_grid_key(queue:getAttr("toX"), queue:getAttr("toY"))
		if self.grids[key] then
			ret[key] = self.grids[key]
		end
	elseif queueConf.queueStatus.massing == status then
		local key = self:get_grid_key(queue:getAttr("fromX"), queue:getAttr("fromY"))
		if self.grids[key] then
			ret[key] = self.grids[key]
		end
	end
	if not next(ret) then
		if not (queue:isFollowing()) then
			gLog.e("queueAoi:addQueue error2: qid=", qid, "queueType=", queue:getQueueType(), "status=", status, queue:getAttr("fromX"), queue:getAttr("fromY"), queue:getAttr("toX"), queue:getAttr("toY"))
		end
		return
	end
	gLog.d("queueAoi:addQueue ref=", qid, "oldRef=", table.keys(self.queueGridRef[qid] or {}), "newRef=", table.keys(ret))

	self.queueGridRef[qid] = ret
	for _,grid in pairs(ret) do
		grid:addQueue(queue)
	end
	-- 推送客户端
	if not isInit then
		local watchers, uid = self:getQueueWatchers(queue), queue:getUid()
		if next(watchers) then
			local playerids = {}
			for _, watcher in pairs(watchers) do
				local uid2 = watcher:get_key()
				if uid2 ~= uid then
					local serverid = watcher:get_serverid()
					if not playerids[serverid] then
						playerids[serverid] = {}
					end
					table.insert(playerids[serverid], uid2)
				end
			end
			if next(playerids) then
				-- gLog.dump(playerids, "queueAoi:addQueue playerids=", 10)
				local msg = queue:packData()
				for serverid, uids in pairs(playerids) do
					require("gateLib"):sendMsgToPlayers(serverid, uids, "updateViewQueue", {queue = msg})
				end
			end
		end
	end
end

-- 删除队列
function queueAoi:removeQueue(queue)
	local qid = queue:getId()
	gLog.d("queueAoi:removeQueue begin", qid)
	local watchers, uid = self:getQueueWatchers(queue), queue:getUid()
	local grids = self.queueGridRef[qid]
	--gLog.d("queueAoi:removeQueue ref=", qid, table.keys(grids or {}))
	if grids then
		for _, grid in pairs(grids) do
			grid:removeQueue(queue)
		end
		self.queueGridRef[qid] = nil
	end

	-- 推送客户端
	if next(watchers) then
		local playerids = {}
		for _, watcher in pairs(watchers) do
			local uid2 = watcher:get_key()
			if uid2 ~= uid then
				local serverid = watcher:get_serverid()
				if not playerids[serverid] then
					playerids[serverid] = {}
				end
				table.insert(playerids[serverid], uid2)
			end
		end
		if next(playerids) then
			local msg = {id = queue:getId()}
			for serverid, uids in pairs(playerids) do
				require("gateLib"):sendMsgToPlayers(serverid, uids, "removeViewQueue", msg)
			end
		end
	end
	gLog.d("queueAoi:removeQueue end", queue:getId())

	-- 检测异常, 后续没bug后删除之
	if svrconf.DEBUG then
		for key,grid in pairs(self.grids) do
			if grid.queues[qid] then
				gLog.e("queueAoi:removeQueue error, qid=", qid, "key=", key)
				break
			end
		end
	end
end

-- 更新队列
function queueAoi:updateQueue(queue, changeKeys)
	local qid, uid, status = queue:getId(), queue:getUid(), queue:getStatus()
	gLog.d("queueAoi:updateQueue begin", qid, uid, status)
	local rmgrids, newgrids, keepgrids = {}, {}, {}
	if (not changeKeys or changeKeys.moveTimeSpan or changeKeys.status) and self.queueGridRef[qid] then --队列路径有变化
		local ret = {} -- 队列当前绑定的格子
		if queueConf.queueStatus.moving == status then
			local railway_queue_aoi = get_static_config().railway_queue_aoi
			local path = queue:getAttr("moveTimeSpan").path or {}
			for i=1,#path-1 do
				if path[i].railway then
					local id1, id2 = mapUtils.get_coord_id(path[i].x, path[i].y), mapUtils.get_coord_id(path[i+1].x, path[i+1].y)
					local tmpkey = id1 > id2 and string.format("%d_%d", id2, id1) or string.format("%d_%d", id1, id2)
					if railway_queue_aoi[tmpkey] then
						for _,key in pairs(railway_queue_aoi[tmpkey]) do
							if not self.grids[key] then
								gLog.e("queueAoi:updateQueue error1", id1, id2, tmpkey)
								break
							else
								ret[key] = self.grids[key]
							end
						end
					else
						gLog.e("queueAoi:updateQueue error2", id1, id2, tmpkey)
					end
				else
					local gx0, gy0 = self:to_grid_xy(path[i].x, path[i].y)
					local gx1, gy1 = self:to_grid_xy(path[i+1].x, path[i+1].y)
					self:lineThroughGrids(ret, gx0, gy0, gx1, gy1)
				end
				-- gLog.d("queueAoi:addQueue qid=", qid, "offset=", self.conf.offset, "ret=", table.keys(ret))
			end
		elseif queueConf.queueStatus.staying == status or queueConf.queueStatus.occupying == status then
			local key = self:get_grid_key(queue:getAttr("toX"), queue:getAttr("toY"))
			if self.grids[key] then
				ret[key] = self.grids[key]
			end
		elseif queueConf.queueStatus.massing == status then
			local key = self:get_grid_key(queue:getAttr("fromX"), queue:getAttr("fromY"))
			if self.grids[key] then
				ret[key] = self.grids[key]
			end
		end
		for key2,grid in pairs(self.queueGridRef[qid]) do
			if not ret[key2] then
				rmgrids[key2] = grid
				grid:removeQueue(queue)
			end
		end
		for key2,grid in pairs(ret) do
			if self.queueGridRef[qid][key2] then
				keepgrids[key2]= grid
			else
				newgrids[key2] = grid
			end
		end
		gLog.d("queueAoi:updateQueue ref1=", qid, uid, "oldRef=", table.keys(self.queueGridRef[qid]), "newRef=", table.keys(ret), "newgrids=", table.keys(newgrids), "rmgrids=", table.keys(rmgrids), "keepgrids=", table.keys(keepgrids))
		self.queueGridRef[qid] = ret
		for _,grid in pairs(ret) do
			grid:addQueue(queue)
		end
	else
		keepgrids = self.queueGridRef[qid] or {}
		--gLog.d("queueAoi:updateQueue ref2=", qid, uid, "keepgrids=", table.keys(keepgrids))
	end
	-- 推送客户端, 队列全量更新
	local check = {}
	if next(newgrids) then
		local watchers = self:getQueueWatchers(queue, newgrids)
		if next(watchers) then
			local playerids = {}
			for _, watcher in pairs(watchers) do
				local uid2 = watcher:get_key()
				if uid2 ~= uid then
					local serverid = watcher:get_serverid()
					if not playerids[serverid] then
						playerids[serverid] = {}
					end
					table.insert(playerids[serverid], uid2)
					check[uid2] = true
				end
			end
			if next(playerids) then
				--gLog.d("queueAoi:updateQueue playerids=", playerids)
				local msg = queue:packData()
				for serverid, uids in pairs(playerids) do
					if next(uids) then
						require("gateLib"):sendMsgToPlayers(serverid, uids, "updateViewQueue", {queue = msg,})
					end
				end
			end
		end
	end
	-- 推送客户端, 队列增量更新
	if next(keepgrids) then
		local watchers = self:getQueueWatchers(queue, keepgrids)
		if next(watchers) then
			local playerids = {}
			for _, watcher in pairs(watchers) do
				local uid2 = watcher:get_key()
				if uid2 ~= uid and not check[uid2] then
					local serverid = watcher:get_serverid()
					if not playerids[serverid] then
						playerids[serverid] = {}
					end
					table.insert(playerids[serverid], uid2)
					check[uid2] = true
				end
			end
			if next(playerids) then
				--gLog.d("queueAoi:updateQueue playerids=", playerids)
				local msg, msgLittle = queue:packData(), queue:packData(changeKeys)
				for serverid, uids in pairs(playerids) do
					if next(uids) then
						if changeKeys then
							require("gateLib"):sendMsgToPlayers(serverid, uids, "updateViewQueueLittle", {queue = msgLittle,})
						else
							require("gateLib"):sendMsgToPlayers(serverid, uids, "updateViewQueue", {queue = msg,})
						end
					end
				end
			end
		end
	end
	-- 推送客户端, 队列移除
	if next(rmgrids) then
		local watchers = self:getQueueWatchers(queue, rmgrids)
		if next(watchers) then
			local playerids = {}
			for _, watcher in pairs(watchers) do
				local uid2 = watcher:get_key()
				if uid2 ~= uid and not check[uid2] then
					local serverid = watcher:get_serverid()
					if not playerids[serverid] then
						playerids[serverid] = {}
					end
					table.insert(playerids[serverid], uid2)
				end
			end
			if next(playerids) then
				--gLog.d("queueAoi:updateQueue playerids=", playerids)
				local msg = {id = qid}
				for serverid, uids in pairs(playerids) do
					if next(uids) then
						require("gateLib"):sendMsgToPlayers(serverid, uids, "removeViewQueue", msg)
					end
				end
			end
		end
	end
end

function queueAoi:lineThroughGrids(ret, x0, y0, x1, y1)
	local dx = math.abs(x1 - x0)
	local dy = math.abs(y1 - y0)
	local err = dx - dy
	local sx = (x0 < x1) and 1 or -1
	local sy = (y0 < y1) and 1 or -1		

	while true do
		local key = mapUtils.get_coord_id(x0, y0)
		if not self.grids[key] then
			gLog.e("queueAoi:lineThroughGrids error", x0, y0)
			break
		else
			ret[key] = self.grids[key]
		end
		if x0 == x1 and y0 == y1 then
			break
		end
		local e2 = 2*err
		if e2 > -dy then
			err = err - dy
			x0 = x0 + sx

		end
		if e2 < dx then
			err = err + dx
			y0 = y0 + sy
		end
	end
end

-- 获取队列的所有观察者
function queueAoi:getQueueWatchers(queue, grids)
	local ret = {}
	if not grids then
		grids = self.queueGridRef[queue:getId()]
	end
	if grids then
		--gLog.d("queueAoi:getQueueWatchers qid=", queue:getId(), "grids=", table.keys(grids))
		for _, grid in pairs(grids) do
			local key = grid:get_key()
			for _, v in pairs(deltaXY) do
				local grid2 = self.grids[key + v]
				if grid2 then
					local watchers = grid2:get_watchers()
					-- gLog.d("queueAoi:getQueueWatchers 2== key=", key, grid2:get_key(), "watchers=", watchers)
					if next(watchers) then
						for k, v in pairs(watchers) do
							ret[k] = v
						end
					end
				end
			end
		end
	end
	return ret
end

-- 增加观察者
function queueAoi:add_watcher(watcher)
	local x, y = watcher:get_position()
	if not x or not y then
		gLog.e("queueAoi:add_watcher", watcher:get_key(), x, y)
	end
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("queueAoi:add_watcher error", watcher:get_key(), x, y)
		return
	end
	grid:add_watcher(watcher)
end

-- 移除观察者
function queueAoi:remove_watcher(watcher)
	--gLog.d("queueAoi:remove_watcher", watcher:get_key(), watcher:get_position())
	local x, y = watcher:get_position()
	local grid = self:get_grid(x, y)
	if not grid then
		gLog.e("queueAoi:remove_watcher error", watcher:get_key(), x, y)
		return
	end
	grid:remove_watcher(watcher)
end

return queueAoi