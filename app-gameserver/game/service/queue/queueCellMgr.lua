--[[
	队列对象管理
]]
local skynet = require("skynet")
local snowflake = require("snowflake")
local queueConf = require("queueConf")
local queueCenter = require("queueCenter"):shareInstance()
local queueCellMgr = class("queueCellMgr")

-- 队列类型-队列类关联
local queueType2Class = {
	[queueConf.queueType.killNpc] = require("queueKillNpcCell"), -- 打怪队列
}

function queueCellMgr:ctor()
	--[[
		队列回收池
		[queueType] = {queue1, queue2, ...},
		...
	]]
	self.recyclePool = {}

	--[[
		索引表
		[indexKey] = {
			[colValue] = {
				[id] = queue,
				...
			},
			...
		},
		...
	]]
	self.indexRef = {}
	-- 初始化索引表
	for indexKey,_ in pairs(queueConf.queueIndexKey) do
		self.indexRef[indexKey] = {}
	end
end

-- 初始化
function queueCellMgr:init()
	-- 加载库数据
	-- self:loadDB()
end

-- 加载库数据
function queueCellMgr:loadDB()
	gLog.d("==queueCellMgr:loadDB begin==")
	--for queueType,cls in pairs(queueType2Class) do
	--	local t_records = cls:get_db_table().select({queueType = queueType}, queueCenter.mapDB)
	--	for k,record in pairs(t_records) do
	--		if svrconf.DEBUG and k == 1 then record:dump() end -- debug
	--		local queue = cls.new(record)
	--		self:addQueue(queue, true)
	--	end
	--end
	gLog.d("==queueCellMgr:loadDB end==")
end

-- 创建队列
function queueCellMgr:createQueue(data)
	gLog.dump(data, "queueCellMgr:createQueue data=", 10)
	assert(data.queueType and data.uid)
	if not data.id then
		data.id = tostring(snowflake.nextid())
	end
	local cls = queueType2Class[data.queueType]
	-- 从回收池取出对象, 无则创建
	local queue = self:popRecyclePool(data.queueType)
	if not queue then
		queue = cls.new(data.id)
	end
	queue:init(data)
	local ok, code = self:addQueue(queue)
	if not ok then
		return false, code
	end
	-- 更新数据库
	queue:updateDB()
	-- 队列创建时的处理
	queue:onCreate()
	return true, queue
end

---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 队列对象维护 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 增加队列
function queueCellMgr:addQueue(queue, isInit, flag)
	if not queue then
		gLog.e("queueCellMgr:addQueue error1")
		return false, gErrDef.Err_ILLEGAL_PARAMS
	end
	local queueType = queue:getAttr("queueType")
	if not queueType then
		gLog.e("queueCellMgr:addQueue error2", self:getId(), self:getQueueType())
		return false, gErrDef.Err_ILLEGAL_PARAMS
	end
	gLog.i("queueCellMgr:addQueue id=", queue:getId(), queueType, queue:getAttr("uid"), "isInit=", isInit, "flag=", flag)
	-- 新队列创建处理
	if not isInit then
		local ok, code = queue:onCreate()
		if not ok then
			return false, code
		end
	end
	-- 索引维护
	self:addIndex(queue)
	-- 增加对象定时器
	queueCenter.queueTimerMgr:addObjTimer(queue)
	-- aoi
	if flag then
		-- aoi更新队列
		if flag == 1 then --1=队列回城先删除后增加, 2=子队列转化先删除后增加
			queueCenter.queueAoiMgr:updateQueue(queue)
		end
	else
		-- aoi增加队列
		queueCenter.queueAoiMgr:addQueue(queue, isInit)
	end
	-- 初始化时, 需要维护一些内存关联信息
	if isInit then
	else
		-- 更新联盟战争队列信息
		-- queueCenter.queueCallbackLogic:updateAllianceQueues(queue)
	end
	return true
end

-- 删除对象
function queueCellMgr:remove(id, flag)
	gLog.i("queueCellMgr:remove id=", id, "flag=", flag)
	local queue = self:query(id)
	if not queue then
		gLog.e("queueCellMgr:remove can't find queue", id, flag)
		return
	end
	-- 索引维护, flag非空=伪删除, 队列转变不删除一些索引
	self:removeIndex(queue, flag and queueConf.queueExceptKey or nil)
	-- 删除计时器
	queueCenter.queueTimerMgr:removeObjTimer(id)
	--
	if not flag then -- 1=队列回城先删除后增加, 2=子队列转化先删除后增加
		-- aoi删除队列
		queueCenter.queueAoiMgr:removeQueue(queue)
		-- 删除队列
		queue:deleteDB()
		-- 加入回收池
		self:pushRecyclePool(queue)
	end
end

--[[
	查询单个队列对象, indexKey 取自 queueConf.queueIndexKey
]]
function queueCellMgr:query(colValue, indexKey, extra)
	if not colValue then
		return
	end
	if not indexKey then
		indexKey = queueConf.queueIndexKey.id
	end
	local queueMap = self.indexRef[indexKey] and self.indexRef[indexKey][colValue]
	if queueMap then
		if extra then
			for exIndexKey, exColValue in pairs(extra) do
				for id, queue in pairs(queueMap) do
					if self.indexRef[exIndexKey] and self.indexRef[exIndexKey][exColValue] and self.indexRef[exIndexKey][exColValue][id] then
					 	-- 找到一个符合条件的对象就返回
					 	return queue
					end
				end
			end
		else
			-- 返回一个对象
			local _, queue = next(queueMap)
			return queue
		end
	end
end

--[[
	查询多个地图对象, indexKey 取自 queueConf.queueIndexKey
]]
function queueCellMgr:batchQuery(colValue, indexKey)
	if not colValue then
		return {}
	end
	if not indexKey then
		indexKey = queueConf.queueIndexKey.id
	end
	return self.indexRef[indexKey] and self.indexRef[indexKey][colValue] or {}
end
----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 队列对象维护 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 索引表维护 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 增加全索引
function queueCellMgr:addIndex(queue, indexKey)
	if not queue then
		return
	end
	if indexKey then
		self:updateIndexSingle(indexKey, queue:getAttr(indexKey), queue:getId(), queue)
	else
		for indexKey,_ in pairs(queueConf.queueIndexKey) do
			self:updateIndexSingle(indexKey, queue:getAttr(indexKey), queue:getId(), queue)
		end
	end
end

-- 更新索引
function queueCellMgr:updateIndex(queue, indexKey, oldValue, newValue)
	if not queue or not indexKey or not queueConf.queueIndexKey[indexKey] or oldValue == newValue then
		return
	end
	if oldValue then
		self:updateIndexSingle(indexKey, oldValue, queue:getId(), nil)
	end
	if newValue then
		self:updateIndexSingle(indexKey, newValue, queue:getId(), queue)
	end
end

-- 移除全索引
function queueCellMgr:removeIndex(queue, except)
	if not queue then
		return
	end
	for indexKey,_ in pairs(queueConf.queueIndexKey) do
		if not except or not except[indexKey] then
			self:updateIndexSingle(indexKey, queue:getAttr(indexKey), queue:getId(), nil)
		end
	end
end

-- 更新单项索引
function queueCellMgr:updateIndexSingle(indexKey, colValue, id, queue)
	gLog.i("queueCellMgr:updateIndexSingle=", id, indexKey, colValue, queue and "add" or "rm")
	if not indexKey or not colValue or not id then
		gLog.e("queueCellMgr:updateIndexSingle error", indexKey, colValue, id)
		return
	end
	if queue then
		-- 添加
		if not self.indexRef[indexKey][colValue] then
			self.indexRef[indexKey][colValue] = {}
		end
		self.indexRef[indexKey][colValue][id] = queue
	else
		-- 删除
		if not self.indexRef[indexKey][colValue] then
			return
		end
		self.indexRef[indexKey][colValue][id] = nil
		if not next(self.indexRef[indexKey][colValue]) then
			self.indexRef[indexKey][colValue] = nil
		end
	end
end
----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 索引表维 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 回收池 begin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- 加入回收池
function queueCellMgr:pushRecyclePool(queue)
	if not queue then
		return
	end
	local queueType = queue:getAttr("queueType")
	if not queueType then
		gLog.e("queueCellMgr:pushRecyclePool error", queueType)
		return
	end
	if not self.recyclePool[queueType] then
		self.recyclePool[queueType] = {}
	end
	if #self.recyclePool[queueType] < 100 then -- 单项队列最多回收100个
		table.insert(self.recyclePool[queueType], queue)
	end
end

-- 从回收池取出对象
function queueCellMgr:popRecyclePool(queueType)
	if self.recyclePool[queueType] and #self.recyclePool[queueType] > 0 then
		return table.remove(self.recyclePool[queueType], 1)
	end
end
----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 回收池 end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


return queueCellMgr