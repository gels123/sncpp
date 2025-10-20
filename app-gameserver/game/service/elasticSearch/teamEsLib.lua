--[[
	队伍名称、简称检索接口
]]
local skynet = require("skynet")
local elasticSearchLib = include "elasticSearchLib"
local teamEsLib = {}

-- 索引、类型
local defaultIndex, defaultType = "rok_activity", "worldteam"

-- 默认最大返回结果数量
local defaultResultSize = 100

function teamEsLib:ctor(index, type)
	if index and type then
		defaultIndex = index
		defaultType = type
	end
end

--[[
	新增、更新
	aid以外的值如果传入nil则不改变原有值
]]
function teamEsLib:set(tid, name, abbr)
	if not tid or not name or not abbr then
		return
	end
	local content = {tid = tid, name = name, abbr = abbr}
	elasticSearchLib:set(defaultIndex, defaultType, tid, content)
end

--[[
	根据aid获取当前昵称数据
]]
function teamEsLib:get(tid)
	return elasticSearchLib:get(defaultIndex, defaultType, tid, true)
end

--[[
	删除
]]
function teamEsLib:delete(tid)
	elasticSearchLib:delete(defaultIndex, defaultType, tid)
end

--[[
	删除所有
]]
function teamEsLib:deleteAll()
	elasticSearchLib:deleteAll(defaultIndex)
end

--[[
	删除所有
]]
function teamEsLib:xdelete()
	elasticSearchLib:xdelete(defaultIndex, defaultType)
end

--[[
	检索
	word 检索词
	size 最大返回条数
]]
function teamEsLib:search(word, size)
	-- 查询词需要全部处理成小写
	local lowWord = ""
	if "string" == type(word) then
		lowWord = string.lower(word)
	end
	size = size or defaultResultSize
	local searchParam = {
		from = 0,
		size = size,
	    query = {
	        multi_match = { -- 多重查询
	            query = table.concat({"*", lowWord, "*"}),
	            fields = {"name", "abbr"},
	            type = "best_fields",
	            tie_breaker = 0.3,
	            minimum_should_match = "30%",
	        }
	    }
	}
	return elasticSearchLib:search(defaultIndex, defaultType, searchParam, true)
end

--[[
	检索
	word 检索词
	size 最大返回条数
]]
function teamEsLib:search2(searchColumn, word, size)
	-- 查询词需要全部处理成小写
	local lowWord = ""
	if "string" == type(word) then
		lowWord = string.lower(word)
	end
	size = size or defaultResultSize
	local searchParam = {
		from = 0,
		size = size,
	    query = {
	        filtered = {
	            query = {
	                wildcard = {
	                    [searchColumn] = table.concat({"*", lowWord, "*"})
	                }
	            },
	        }
	    }
	}
	return elasticSearchLib:search(defaultIndex, defaultType, searchParam, true)
end

return teamEsLib