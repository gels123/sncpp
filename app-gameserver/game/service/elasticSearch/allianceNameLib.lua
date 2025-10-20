--[[
	联盟名称、简称检索接口
]]
local elasticSearchLib = include "elasticSearchLib"
local allianceNameLib = class("allianceNameLib")

local defaultIndex, defaultType = "game", "alliance"

-- 默认最大返回结果数量
local defaultResultSize = 100

-- 新增设置类型
function allianceNameLib.setType(t)
	defaultType = t
end

-- 新增设置类型
function allianceNameLib.getType()
	return defaultType
end

--[[
	新增、更新
	aid以外的值如果传入nil则不改变原有值
]]
function allianceNameLib.set(kid, aid, name, abbr)
	if not aid then
		return
	end
	local oldData = {}
	if not kid or not name or not abbr then
		-- 读取原有数据
		oldData = allianceNameLib.get(aid)
	end
	local content = {
		kid = kid or oldData.kid,
		aid = aid,
		name = name or oldData.name,
		abbr = abbr or oldData.abbr,
	}
	elasticSearchLib:set(defaultIndex, defaultType, aid, content)
end

--[[
	根据aid获取当前昵称数据
]]
function allianceNameLib.get(aid)
	local result = elasticSearchLib:get(defaultIndex, defaultType, aid, true)
	return result
end

--[[
	删除
]]
function allianceNameLib.delete(aid)
	elasticSearchLib:delete(defaultIndex, defaultType, aid)
end

--[[
	检索
	word 检索词
	size 最大返回条数
]]
function allianceNameLib.search(kid, searchColumn, word, size)
	-- 查询词需要全部处理成小写
	local lowWord
	if word and "string" == type(word) then
		lowWord = string.lower(word)
	else
		lowWord = ""
	end
	local retSize = size or defaultResultSize
	local extraCol = nil
	if kid then
		extraCol = {
	        ["and"] = {
	            {
	                term = {
	                    kid = kid
	                }
	            }
	        }
		}
	end
	local searchParam = {
		from = 0,
		size = retSize,
	    query = {
	        filtered = {
	            query = {
	                wildcard = {
	                    [searchColumn] = table.concat({"*",lowWord,"*"})
	                }
	            },
	            filter = extraCol
	        }
	    }
	}
	return elasticSearchLib:search(defaultIndex, defaultType, searchParam, true)
end

function allianceNameLib.getCount(kid, searchColumn, word)
	-- 查询词需要全部处理成小写
	local lowWord
	if word and "string" == type(word) then
		lowWord = string.lower(word)
	else
		lowWord = ""
	end
	
	local retSize = 0

	local extraCol = nil
	if kid then
		extraCol = {
	        ["and"] = {
	            {
	                term = {
	                    kid = kid
	                }
	            }
	        }
		}
	end
	local searchParam = {
		from = 0,
		size = retSize,
	    query = {
	        filtered = {
	            query = {
	                wildcard = {
	                    [searchColumn] = table.concat({"*",lowWord,"*"})
	                }
	            },
	            filter = extraCol
	        }
	    }
	}

	local result = elasticSearchLib:search(defaultIndex, defaultType, searchParam, false, true)
	return result
end

return allianceNameLib