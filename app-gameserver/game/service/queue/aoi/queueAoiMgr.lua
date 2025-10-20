--[[
	队列视野管理
--]]
local skynet = require "skynet"
local queueConf = require "queueConf"
local queueAoiC = require "queueAoi"
local queueWatcherC = require "queueWatcher"
local queueCenter = require("queueCenter"):shareInstance()
local queueAoiMgr = class("queueAoiMgr")

function queueAoiMgr:ctor()
	-- 队列AOI列表
	self.aoiList = {}
	-- 观察者列表
	self.watcherList = {}
	-- 批量推送
	self.batch = {}
end

-- 初始化
function queueAoiMgr:init(width, height, confs)
	if svrconf.DEBUG then
		gLog.d("queueAoiMgr:init", width, height, table2string(confs))
	end
	assert(width and height and type(confs) == "table")
	self.width = width
	self.height = height
	self.confs = confs
	
	for k, v in ipairs(confs) do
		if v.queueTypes then
			self.aoiList[k] = queueAoiC.new(width, height, v)
		end
	end
end

-- 增加队列
function queueAoiMgr:addQueue(queue, isInit)
	gLog.d("queueAoiMgr:addQueue qid=", queue:getId())
	if queue:getAttr("queueType") == queueConf.queueType.brigade then
		return
	end
	for k, v in pairs(self.aoiList) do
		v:addQueue(queue, isInit)
	end
end

-- 删除队列
function queueAoiMgr:removeQueue(queue)
	gLog.d("queueAoiMgr:removeQueue qid=", queue:getId())
	if queue:getAttr("queueType") == queueConf.queueType.brigade then
		return
	end
	for k, v in pairs(self.aoiList) do
		v:removeQueue(queue)
	end
end

-- 更新队列
function queueAoiMgr:updateQueue(queue, changeKeys)
	gLog.d("queueAoiMgr:updateQueue qid=", queue:getId())
	if queue:getAttr("queueType") == queueConf.queueType.brigade then
		return
	end
	self.batch[queue] = true
	if self.batch[queue] then
		self.batch[queue] = nil
		for k, v in pairs(self.aoiList) do
			v:updateQueue(queue, changeKeys)
		end
	end
end

-- 获取观察者
function queueAoiMgr:get_watcher(playerid)
	if not self.watcherList[playerid] then
		self.watcherList[playerid] = queueWatcherC.new(playerid)
	end
	return self.watcherList[playerid]
end

-- 移除观察者
function queueAoiMgr:remove_watcher(playerid)
	local watcher = self.watcherList[playerid]
	if watcher then
		--gLog.d("queueAoiMgr:remove_watcher", playerid, watcher:get_position())
		self.watcherList[playerid] = nil
		for k, v in pairs(self.aoiList) do
			v:remove_watcher(watcher)
		end
	end
end

-- 请求视野内队列信息
function queueAoiMgr:reqViewMarch(serverid, playerid, x, y, radius)
	gLog.d("queueAoiMgr:reqViewMarch", serverid, playerid, x, y, radius)
	--参数校验
	if not playerid or not x or not y or not radius then
		gLog.e("queueAoiMgr:reqViewMarch error1")
		return false, global_code.error_param
	end
	if x > queueConf.map_size then x = queueConf.map_size end
	if y > queueConf.map_size then y = queueConf.map_size end
	--获取观察者
	local watcher = self:get_watcher(playerid)
	--根据半径获取aoi等级
	local lv = nil
	for i = 1, #self.confs, 1 do
		if not self.confs[i].queueTypes then
			lv = i
			break
		elseif radius <= self.confs[i].queueOffsetMax then
			lv = i
			break
		end
	end
	if not lv then
		lv = #self.confs
	end
	--
	local oldx, oldy, oldlv, oldserverid = watcher:get_position()
	if oldx and oldy and oldlv and oldserverid then
		gLog.d("queueAoiMgr:reqViewMarch 2= serverid=", serverid, "playerid=", playerid, lv, "oldserverid=", oldserverid, oldlv, oldx, oldy)
		if lv == oldlv then
			if self.aoiList[lv] then
				local ogx, ogy = self.aoiList[lv]:to_grid_xy(oldx, oldy)
				local gx, gy = self.aoiList[lv]:to_grid_xy(x, y)
				if ogx == gx and ogy == gy then -- 还在同一个九宫格 不做处理
					return true, lv
				else
					self.aoiList[lv]:remove_watcher(watcher)
				end
			end
		else
			if self.aoiList[oldlv] then
				self.aoiList[oldlv]:remove_watcher(watcher)
			end
		end
	end
	watcher:set_position(x, y, lv, serverid)
	-- 视野太大, 不下发任何队列信息
	if not self.aoiList[lv] then
		return true, lv
	end
	self.aoiList[lv]:add_watcher(watcher)
	--gLog.d("queueAoiMgr:reqViewMarch add_watcher", playerid, watcher:get_position())

	-- 队列对象
	local addQueues, delQueues = self.aoiList[lv]:getWatcherQueues(watcher, playerid)
	--gLog.dump(addQueues, "queueAoiMgr:reqViewMarch addQueues lv="..lv, 3)
	--gLog.dump(delQueues, "queueAoiMgr:reqViewMarch delQueues lv="..lv, 3)
	return true, lv, addQueues, delQueues
end

return queueAoiMgr