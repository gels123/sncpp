--[[
	玩家数据缓存
--]]
local skynet = require("skynet")
local playerDataLib = require "playerDataLib"
local cacheCenter = require("cacheCenter"):shareInstance()
local cachePlayer = class("cachePlayer")

-- 构造
function cachePlayer:ctor(uid)
    self.uid = uid                      -- 玩家ID
    self.module = "cacheplayer"	        -- 数据表名
    self.data = nil		                -- 数据
end

-- 默认数据
function cachePlayer:defaultData()
    return {
        uid = self.uid,
        aid = 0,
    }
end

-- [override]初始化
function cachePlayer:init()
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
    gLog.dump(self, "cachePlayer:init")
end

-- 查询数据库
function cachePlayer:queryDB()
    assert(self.module, "cachePlayer:queryDB error!")
    return playerDataLib:query(cacheCenter.kid, self.uid, self.module)
end

-- 更新数据库
function cachePlayer:updateDB()
    local data = self:getDataDB()
    assert(self.module and data, "cachePlayer:updateDB error!")
    playerDataLib:sendUpdate(cacheCenter.kid, self.uid, self.module, data)
end

-- 获取存库数据
function cachePlayer:getDataDB()
    return self.data
end

function cachePlayer:getAttr(key)
    return self.data[key]
end

function cachePlayer:getAttrs(keys, ret)
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

function cachePlayer:setAttr(key, value, noSave)
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

function cachePlayer:setAttrs(keyValues, noSave)
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

return cachePlayer