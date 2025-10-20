--[[
	rpg地图工具类
]]
local mapConf = require "mapConf"
local mapUtils = {}

-- 根据xy获取坐标ID
function mapUtils:getCoordId(x, y)
	return y * 10000 + x
end

function mapUtils:getCoordXy(id)
	local y = math.floor(id / 10000)
	local x = id % 10000
	return x, y
end

return mapUtils