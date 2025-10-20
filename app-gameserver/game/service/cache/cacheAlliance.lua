--[[
	联盟数据缓存
--]]
local skynet = require("skynet")
local playerDataLib = require "playerDataLib"
local cacheCenter = require("cacheCenter"):shareInstance()
local cacheAlliance = class("cacheAlliance")

-- 构造
function cacheAlliance:ctor(aid)
    self.aid = aid                      -- 联盟ID
    self.module = "cachealliance"	    -- 数据表名
    self.data = nil		                -- 数据
end

-- 默认数据
function cacheAlliance:defaultData()
    return {
        aid = self.aid,
    }
end

-- [override]初始化
function cacheAlliance:init()
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
    gLog.dump(self, "cacheAlliance:init")
end

-- 查询数据库
function cacheAlliance:queryDB()
    assert(self.module, "cacheAlliance:queryDB error!")
    return playerDataLib:query(cacheCenter.kid, self.aid, self.module)
end

-- 更新数据库
function cacheAlliance:updateDB()
    local data = self:getDataDB()
    assert(self.module and data, "cacheAlliance:updateDB error!")
    playerDataLib:sendUpdate(cacheCenter.kid, self.aid, self.module, data)
end

-- 获取存库数据
function cacheAlliance:getDataDB()
    return self.data
end

function cacheAlliance:getAttr(key)
    return self.data[key]
end

function cacheAlliance:getAttrs(keys, ret)
    if keys == nil then
        return self.data
    else
        ret = ret or {}
        for _,key in pairs(keys) do
            ret[key] = self.data[key]
        end
        return ret
    end
end

function cacheAlliance:setAttr(key, value, noSave)
    if value == "nil" then
        if self.data[key] ~= nil then
            self.data[key] = nil
            if not noSave then
                self:updateDB()
            end
        end
    else
        if self.data[key] ~= value then
            self.data[key] = value
            if not noSave then
                self:updateDB()
            end
        end
    end
end

function cacheAlliance:setAttrs(keyValues, noSave)
    local save = false
    for key,value in pairs(keyValues) do
        if value == "nil" then
            if self.data[key] ~= nil then
                self.data[key] = nil
                save = true
            end
        else
            if self.data[key] ~= value then
                self.data[key] = value
                save = true
            end
        end
    end
    if save and not noSave then
        self:updateDB()
    end
end

return cacheAlliance
