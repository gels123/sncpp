--[[
    配置所有的本地数据到 sharedata 中
--]]
local sharedataLib = require "sharedataLib"
local skynet = require "skynet"
local localDataLogic = class("localDataLogic")

-- 设置到 sharedata 服务中
function localDataLogic:setShareData(key, value, isUpdate)
    assert("string" == type(key), "key is not string!")
    assert(value, "value is nil!")
    if "table" == type(value) then
        if not next(value) then
            gLog.i(string.format("local data \"%s\" is empty!", key))
        end
    end
    if isUpdate then
        sharedataLib.update(key, value)
    else
        sharedataLib.new(key, value)
    end
end

-- 加载文件(不使用require方便热更)
function localDataLogic:load(tbname)
    tbname = string.format("game/service/localData/localTb/%s.lua", tbname)
    local s = io.readfile(tbname)
    assert(s, "localDataLogic:load failed, tbname="..tbname)
    local f = load(s, tbname, "t")
    assert(f, "localDataLogic:load failed, tbname="..tbname)
    return f()
end

-- 通用table格式化
function localDataLogic:convertTab(tbname, key)
    local tab = self:load(tbname) -- require(tbname)
    if not key then
        return tab
    end
    local ret = {}
    for k,v in pairs(tab) do
        if type(key) == "string" then
            ret[v[key]] = v
        elseif type(key) == "table" then
            local t = ret
            for i=1,#key do
                local k = key[i]
                if i < #key then
                    if not t[v[k]] then
                        t[v[k]] = {}
                    end
                    t = t[v[k]]
                else
                    if type(k) == "string" then
                        t[v[k]] = v
                    else
                        assert(false, "localDataLogic:convertTab error: unkown key!"..tbname)
                    end
                end
            end
        end
    end
    --gLog.dump(ret, string.format("localDataLogic:convertTab tabName=%s", tbname))
    return ret
end

-- 配置所有的local data
function localDataLogic:init(isUpdate)
    -- 道具配置(测试)
    self:setShareData("itemCfg", self:convertTab("test/item_cfg", {"Id"}), isUpdate)
end

-- 配置数据自行组装样例
function localDataLogic:getTestItem()
    local ret = {}
    local test_item = self:load("test/item_cfg")
    for k,v in pairs(test_item) do
        ret[v.id] = v
    end
    --gLog.dump(ret, "localDataLogic:getTestItem ret=")
    return ret
end

return localDataLogic
