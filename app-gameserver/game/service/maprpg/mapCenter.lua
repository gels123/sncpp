--[[
	rpg地图服务中心
]]
local skynet = require ("skynet")
local mapConf = require "mapConf"
local svrFunc = require ("svrFunc")
local gLog = require ("newLog")
local mapUtils = require ("mapUtils")
local mapLib = require "mapLib"
local serviceCenterBase = require("serviceCenterBase2")
local mapCenter = class("mapCenter", serviceCenterBase)

-- 构造
function mapCenter:ctor()
	mapCenter.super.ctor(self)
end

-- 初始化
function mapCenter:init(kid, idx)
	gLog.i("==mapCenter:init begin==", kid, idx)
	self.super.init(self, kid)

	-- 服务ID
	self.idx = idx
	-- 设置随机种子
	svrFunc.setRandomSeed()

	local time = skynet.now()
	-------------- 模块创建 --------------
	-- 计时器管理器
	self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)
	-- 地图管理器
	self.mapMgr = require("mapMgr").new()

    -- 地图对象初始化
    self.mapMgr:init()

    gLog.i("==mapCenter:init end==", kid, "cost time=", skynet.now() - time)
	return true
end

-- 查找未满员的地图
function mapCenter:findMap(tp)
	local redisLib = require("redisLib")
	local ret = redisLib:zRange(self.mapMgr:findMapKey(tp), 0, 1)
	gLog.dump(ret, "mapCenter:findMap ret=")
	if ret then
		return tonumber(ret[1])
	end
end

-- 进入地图
function mapCenter:enterMap(uid, tp, mapid, move)
	local map = self.mapMgr:getMap(tp, mapid)
	return map:enterMap(uid, move)
end

-- 离开地图
function mapCenter:exitMap(uid, tp, mapid)
	local map = self.mapMgr:getMap(tp, mapid, true)
	if map then
		return map:exitMap(uid)
	end
end

-- 移动
function mapCenter:move(uid, tp, mapid, move)
	local map = self.mapMgr:getMap(tp, mapid, true)
	if map then
		return map:move(uid, move)
	end
end

-- 计时器回调
function mapCenter:timerCallback(data)
	if dbconf.DEBUG then
		gLog.d("mapCenter:timerCallback data=", table2string(data))
	end
end

return mapCenter