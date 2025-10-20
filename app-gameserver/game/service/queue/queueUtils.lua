--[[
	行军队列工具类
]]
local skynet = require "skynet"
local queueCenter = require("queueCenter"):shareInstance()
local queueUtils = class("queueUtils")

function queueUtils.get_coord_id(x, y)
	return x * 10000 + y
end

-- 计算地图两点间距离
function queueUtils:getDistance(x1, y1,  x2, y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

return queueUtils
