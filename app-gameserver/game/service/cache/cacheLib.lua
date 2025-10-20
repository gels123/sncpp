--[[
	缓存服务对外接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local cacheLib = class("cacheLib")

-- 获取服务地址
function cacheLib:getAddress(kid)
    return svrAddrMgr.getSvr(svrAddrMgr.cacheSvr, kid)
end

-- call调用
function cacheLib:call(kid, ...)
    return skynet.call(self:getAddress(kid), "lua", ...)
end

-- send调用
function cacheLib:send(kid, ...)
    skynet.send(self:getAddress(kid), "lua", ...)
end

-- 获取玩家单个属性
function cacheLib:getPlayerAttr(kid, uid, key)
    return self:call(kid, "getPlayerAttr", uid, key)
end

-- 获取玩家多个属性
-- @keys 若不传则返回所有属性
function cacheLib:getPlayerAttrs(kid, uid, keys)
    return self:call(kid, "getPlayerAttrs", uid, keys)
end

-- 设置玩家单个属性
function cacheLib:setPlayerAttr(kid, uid, key, value, noSave)
    self:send(kid, "setPlayerAttr", uid, key, value, noSave)
end

-- 设置玩家多个属性
function cacheLib:setPlayerAttrs(kid, uid, keyValues, noSave)
    self:send(kid, "setPlayerAttrs", uid, keyValues, noSave)
end

-- 获取联盟单个属性
function cacheLib:getCacheAlliance(kid, aid, key)
    return self:call(kid, "getCacheAlliance", aid, key)
end

-- 获取联盟多个属性
-- @keys 若不传则返回所有属性
function cacheLib:getAllianceAttrs(kid, aid, keys)
    return self:call(kid, "getAllianceAttrs", aid, keys)
end

-- 设置联盟单个属性
function cacheLib:setAllianceAttr(kid, aid, key, value, noSave)
    self:send(kid, "getAllianceAttrs", aid, key, value, noSave)
end

-- 设置联盟多个属性
function cacheLib:setAllianceAttrs(kid, aid, keyValues, noSave)
    self:send(kid, "setAllianceAttrs", aid, keyValues, noSave)
end

-- 获取玩家多个属性和联盟多个属性
-- @keys1 玩家属性keys, 若不传则返回所有属性
-- @keys2 联盟属性keys, 若不传则返回所有属性
function cacheLib:getPlayerAllianceAttrs(kid, uid, keys1, keys2)
    return self:call(kid, "getPlayerAllianceAttrs", uid, keys1, keys2)
end

return cacheLib
