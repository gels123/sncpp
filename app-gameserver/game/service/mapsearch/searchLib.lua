--[[
	寻路服务接口
]]
local skynet = require ("skynet")
local searchLib = class("searchLib")

-- 服务数量
searchLib.serviceNum = svrconf.DEBUG and 1 or 8

-- 根据id返回服务id
function searchLib:idx(id)
	return (id - 1) % searchLib.serviceNum + 1
end

-- 获取地址
function searchLib:getAddress(serverid, id)
	return svrAddressMgr.getSvr(svrAddressMgr.searchSvr, serverid, self:idx(id))
end

--[[
    两点间寻路
    @serverid       [必填]服务器ID
    @id             [必填]一般传UID
    @startX startY  [必填]寻路开始节点
    @endX endY      [必填]寻路结束节点
    @aid      		[必填]联盟ID
    @speed      	[必填]步行速度
    @railwayTime    [必填]火车站到站行驶时间
    @isReturn    	[必填]是否回程
    @ret 			= {path = {{x = 1, y = 1, railway = false}, {x = 2, y = 2, railway = false}, ...}}
]]
function searchLib:getPath(serverid, id, startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
    return skynet.call(self:getAddress(serverid, id), "lua", "getPath", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
end

--[[
    两点间寻路
    @serverid       [必填]服务器ID
    @id             [必填]一般传UID
    @startX startY  [必填]寻路开始节点
    @endX endY      [必填]寻路结束节点
    @aid      		[必填]联盟ID
    @speed      	[必填]步行速度
    @railwayTime    [必填]火车站到站行驶时间
    @isReturn    	[必填]是否回程
    @ret 			= true or false
]]
function searchLib:bgetPath(serverid, id, startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
	return skynet.call(self:getAddress(serverid, id), "lua", "bgetPath", startX, startY, endX, endY, aid, speed, railwayTime, isReturn)
end

-- 更新联盟-铁路关联
function searchLib:updateRailwayMap(serverid, x, y, aid)
	for id = 1, require("searchLib").serviceNum do
		skynet.send(self:getAddress(serverid, id), "lua", "updateRailwayMap", x, y, aid)
	end
end

-- 更新联盟-关卡码头关联
function searchLib:updateCheckMap(serverid, x, y, aid)
	for id = 1, require("searchLib").serviceNum do
		skynet.send(self:getAddress(serverid, id), "lua", "updateCheckMap", x, y, aid)
	end
end

return searchLib