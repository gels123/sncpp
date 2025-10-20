--[[
	地图对象刷新和管理
]]
local skynet = require("skynet")
local mapCenter = require("mapCenter"):shareInstance()
local mapRefreshMgr = class("mapRefreshMgr")

function mapRefreshMgr:ctor()
	-- 所有地图对象
	self.objs = {}

	-- 补刷计时器ID
	self.supplyTimerId = nil
	-- 补刷计时器间隔
	self.supplyTimerInterval = 3600
	-- 重刷计时器ID
	self.resetTimerId = nil
	-- 重刷计时器间隔
	self.resetTimerInterval = 4 * 3600
end

-- 初始化
function mapRefreshMgr:init()
	--gLog.d("mapRefreshMgr:init", self.class.__cname, self:getSupplyTimerInterval())
	self.supplyTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onSupplyTimerCallback), svrFunc.systemTime() + self:getSupplyTimerInterval())
	self.resetTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onResetTimerCallback), svrFunc.systemTime() + self:getResetTimerInterval())
end

-- 初始化完毕
function mapRefreshMgr:init_over()
	
end

-- 获取补刷计时器间隔
function mapRefreshMgr:getSupplyTimerInterval()
	return self.supplyTimerInterval
end

-- 补刷计时器回调
function mapRefreshMgr:onSupplyTimerCallback()
	gLog.d("mapRefreshMgr:onSupplyTimerCallback begin", self.class.__cname)
	self.supplyTimerId = nil
	pcall(self.doSupplyRefresh, self)
	self.supplyTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onSupplyTimerCallback), svrFunc.systemTime() + self:getSupplyTimerInterval())
	gLog.d("mapRefreshMgr:onSupplyTimerCallback end", self.class.__cname)
end

-- 执行补刷
function mapRefreshMgr:doSupplyRefresh()

end

-- 获取重刷计时器间隔
function mapRefreshMgr:getResetTimerInterval()
	return self.resetTimerInterval
end

-- 重刷计时器回调
function mapRefreshMgr:onResetTimerCallback()
	gLog.d("mapRefreshMgr:onResetTimerCallback")
	self.resetTimerId = nil
	pcall(self.doResetRefresh, self)
	self.resetTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onResetTimerCallback), svrFunc.systemTime() + self:getResetTimerInterval())
end

-- [override]执行重刷
function mapRefreshMgr:doResetRefresh()

end

-- 增加对象
function mapRefreshMgr:add_object(obj)
	local objid = obj:get_objectid()
	self.objs[objid] = obj
end

-- 删除对象
function mapRefreshMgr:remove_object(obj)
	local objid = obj:get_objectid()
	self.objs[objid] = nil
end

function mapRefreshMgr:pack_type_objects(v, type, subtype, ret)

end

return mapRefreshMgr

