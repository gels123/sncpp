--[[
    es搜索服务接口: 增删改查
--]]

local skynet = require "skynet"
local elasticSearchLib = class("elasticSearchLib")

-- 获取服务地址
function elasticSearchLib:getAddr()
    return svrAddrMgr.getSvr(svrAddrMgr.elasticSearchSvr)
end

--[[
    设置
]]
function elasticSearchLib:set(index, type, id, content)
	skynet.send(self:getAddr(), "lua", "set", index, type, id, content)
end

-- 获取 onlySource是否只获取存入的数据
function elasticSearchLib:get(index, type, id, onlySource)
    local _,get_ret = skynet.call(self:getAddr(),"lua","get",index,type,id)
    gLog.dump(get_ret,"get_ret ret = ",10)

    if onlySource then
        return self:getSourceData(get_ret)
    else
        return get_ret
    end
end

--[[
    删除
    eg:
        delete(index, type, id) 删除索引类型下的单个
        delete(index) 删除索引
]]
function elasticSearchLib:delete(index, type, id)
	skynet.send(self:getAddr(), "lua", "delete", index, type, id)
end

--[[
    是否存在
]]
function elasticSearchLib:exist(index, type, id)
    local status,ret = skynet.call(self:getAddr(), "lua", "exist", index, type, id)
    gLog.dump(ret, "elasticSearchLib:exist status="..tostring(status), 10)
    return ret
end

--[[
    搜索
    onlySource 是否只获取存入的数据
    onlyCount 是否只返回数量
]]
function elasticSearchLib:search(index, type, searchParam, onlySource, onlyCount)
	local status,ret = skynet.call(self:getAddr(), "lua", "search", index, type, searchParam)
    gLog.dump(ret, "elasticSearchLib:search status="..tostring(status), 10)

    if onlySource then
        return self:getSourceData(ret)
    elseif onlyCount then
        return self:getCount(ret)
    else
        return ret
    end
end

function elasticSearchLib:getSourceData(data)
    if data and "table" == type(data) and data.hits and data.hits.hits then
        local hits = data.hits.hits
        local ret = {}
        for index, retSet in pairs(hits) do
            if retSet._source then
                local retCell = {}
                for i, v in pairs(retSet._source) do
                    retCell[i] = v
                end
                table.insert(ret, retCell)
            end
        end
        return ret
    end
end

function elasticSearchLib:getCount(data)
    local count = 0
    if data and "table" == type(data) and data.hits then
        count = data.hits.total
    end
    return count
end

return elasticSearchLib