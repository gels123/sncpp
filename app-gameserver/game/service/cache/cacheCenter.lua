--[[
	缓存服务中心
--]]
local skynet = require("skynet")
local serviceCenterBase = require("serviceCenterBase2")
local cacheCenter = class("cacheCenter", serviceCenterBase)

-- 构造
function cacheCenter:ctor()
	self.super.ctor(self)
end

-- 初始化
function cacheCenter:init(kid)
    gLog.i("==cacheCenter:init begin==", kid)
	cacheCenter.super.init(self, kid)

	-- 计时器管理器
	self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)
	-- 缓存数据管理
	self.cacheMgr = require("cacheMgr").new()

    gLog.i("==cacheCenter:init end==", kid)
    return true
end

-- 获取玩家单个属性
function cacheCenter:getPlayerAttr(uid, key)
	local cachePlayer = self.cacheMgr:getCachePlayer(uid)
	return cachePlayer:getAttr(key)
end

-- 获取玩家多个属性
-- @keys 若不传则返回所有属性
function cacheCenter:getPlayerAttrs(uid, keys)
	local cachePlayer = self.cacheMgr:getCachePlayer(uid)
	return cachePlayer:getAttrs(keys)
end

-- 设置玩家单个属性
function cacheCenter:setPlayerAttr(uid, key, value, noSave)
	local cachePlayer = self.cacheMgr:getCachePlayer(uid)
	cachePlayer:setAttr(key, value, noSave)
end

-- 设置玩家多个属性
function cacheCenter:setPlayerAttrs(uid, keyValues, noSave)
	local cachePlayer = self.cacheMgr:getCachePlayer(uid)
	cachePlayer:setAttrs(keyValues, noSave)
end

-- 获取联盟单个属性
function cacheCenter:getCacheAlliance(aid, key)
	local cacheAlliance = self.cacheMgr:getCacheAlliance(aid)
	return cacheAlliance:getAttr(key)
end

-- 获取联盟多个属性
-- @keys 若不传则返回所有属性
function cacheCenter:getAllianceAttrs(aid, keys)
	local cacheAlliance = self.cacheMgr:getCacheAlliance(aid)
	return cacheAlliance:getAttrs(keys)
end

-- 获取玩家多个属性和联盟多个属性
-- @keys1 玩家属性keys, 若不传则返回所有属性
-- @keys2 联盟属性keys, 若不传则返回所有属性
function cacheCenter:getPlayerAllianceAttrs(uid, keys1, keys2)
	--gLog.d("cacheCenter:getPlayerAllianceAttrs", uid, keys1, keys2)
	local cachePlayer = self.cacheMgr:getCachePlayer(uid)
	local uidAttrs = cachePlayer:getAttrs(keys1)
	local aidAttrs = {}
	if uidAttrs.aid and uidAttrs.aid > 0 then
		local cacheAlliance = self.cacheMgr:getCacheAlliance(uidAttrs.aid)
		aidAttrs = cacheAlliance:getAttrs(keys2)
	end
	return uidAttrs, aidAttrs
end

-- 设置联盟单个属性
function cacheCenter:setAllianceAttr(aid, key, value, noSave)
	local cacheAlliance = self.cacheMgr:getCacheAlliance(aid)
	cacheAlliance:setAttr(key, value, noSave)
end

-- 设置联盟多个属性
function cacheCenter:setAllianceAttrs(aid, keyValues, noSave)
	local cacheAlliance = self.cacheMgr:getCacheAlliance(aid)
	cacheAlliance:setAttrs(keyValues, noSave)
end

-- 计时器回调
function cacheCenter:timerCallback(data)
	-- if dbconf.DEBUG then
	-- 	gLog.d("cacheCenter:timerCallback data=", table2string(data))
	-- end
	local id, typ = data.id, data.timerType
	if self.timerMgr:hasTimer(id, typ) then
		if typ == 0 then
			self.cacheMgr:delCachePlayer(id)
		elseif typ == 1 then
			self.cacheMgr:delCacheAlliance(id)
		end
		--gLog.dump(self.cacheMgr, "cacheCenter:timerCallback cacheMgr=")
	end
end

return cacheCenter
