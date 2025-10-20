--[[
	玩家昵称检索接口
]]

require("splitIntoGroupOfNumUtf8")

local elasticSearchLib = include "elasticSearchLib"

local playerNickNameLib = {}

local defaultIndex = "game"

local defaultType = "user"

-- 默认最大返回结果数量
local defaultResultSize = 100

--[[
	新增、更新
]]
function playerNickNameLib.set(kid, uid, nickname)
    -- local splitstrTable = splitIntoGroupOfNumUtf8( nickname, 2 )
    -- local finalStr = table.concat(splitstrTable," ")
    -- print("finalStr = ",finalStr)
	local content = {
		kid = kid,
		uid = uid,
		nickname = nickname,
		-- nicknameSplit = finalStr,
	}
	elasticSearchLib:set(defaultIndex, defaultType, uid, content)
end

--[[
	根据uid获取当前昵称数据
]]
function playerNickNameLib.get(uid)
	local result = elasticSearchLib:get(defaultIndex, defaultType, uid, true)
	return result
end

--[[
	删除
]]
function playerNickNameLib.delete(uid)
	elasticSearchLib:delete(defaultIndex, defaultType, uid)
end

--[[
	检索
	word 检索词
	size 最大返回条数
]]
function playerNickNameLib.search(kid, word, size)
	-- 查询词需要全部处理成小写
	local lowWord
	if word and "string" == type(word) then
		lowWord = string.lower(word)
		-- lowWord = string.gsub(lowWord, "%s+", "*") -- 把空格处理为*通配符（现在es服已经不进行分词，可以支持空格查询了）
	else
		lowWord = ""
	end
	local retSize = size or defaultResultSize

	-- local searchParam = {
 --        ["query"] = {
 --            ["multi_match"] = {
 --            	["from"] = 0,
	-- 			["size"] = defaultResultSize,
 --                ["type"] = "most_fields",
 --                ["query"] = lowWord,
 --                ["fields"] = { "nickname", "nicknameSplit" },
 --            }
 --        }
	-- }
	-- local searchParam = {
	-- 	["query"] = {
 --            ["match"] = {
	--             ["nickname"] = {
	--             	["query"] = lowWord,
	--             	["fuzziness"] = "AUTO",
	--             	["operator"] = "and",
	-- 	        }
 --            }
 --        }
	-- }
	-- local searchParam = {
 --    	["from"] = 0,
	-- 	["size"] = retSize,
	-- 	["query"] = {
 --            ["wildcard"] = {
 --            	["kid"] = kid,
	--             ["nickname"] = table.concat({"*",lowWord,"*"})
	--             -- ["nickname"] = table.concat({"*",lowWord})
	--             -- ["nickname"] = table.concat({lowWord,"*"})
	--             -- ["nickname"] = lowWord
 --            }
 --        }
	-- }
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
	                    nickname = table.concat({"*",lowWord,"*"})
	                }
	            },
	            filter = extraCol
	        }
	    }
	}

	local result = elasticSearchLib:search(defaultIndex, defaultType, searchParam, true)
	return result
end

function playerNickNameLib.getCount(kid, word)
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
	                    nickname = table.concat({"*",lowWord,"*"})
	                }
	            },
	            filter = extraCol
	        }
	    }
	}

	local result = elasticSearchLib:search(defaultIndex, defaultType, searchParam, false, true)
	return result
end

return playerNickNameLib