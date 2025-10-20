--[[
	运营日志打点对外接口
]]
local skynet = require ("skynet")
local logLib = class("logLib")

-- 获取服务地址
function logLib:getAddress()
	return svrAddrMgr.getSvr(svrAddrMgr.logSvr, kid)
end

-- call调用
function logLib:call(...)
	return skynet.call(self:getAddress(), "lua", ...)
end

-- send调用
function logLib:send(...)
	skynet.send(self:getAddress(), "lua", ...)
end

-------------------------------------------------数数日志开始------------------------------------------------->>>
-- 填充日志通用信息
function logLib:addLogCommInfo(accountId, logData)
    if not logData["#distinct_id"] then
    	local ret
    	if AgentManagerInst then -- agent服务
    		local player = AgentManagerInst:get_player(accountId)
    		ret = player and player:getLog4Gm()
    	else -- 非agent服务
        	ret = require("gateLib"):callPlayer(kid, accountId, "getLog4Gm")
        end
        if ret then
            table.merge(logData, ret)
        end
    end
    return logData["#distinct_id"]
end

function logLib:getDistinctId(accountId)
	if AgentManagerInst then -- agent服务
		local player = AgentManagerInst:get_player(accountId)
		return player and player:getDistinctId()
	else -- 非agent服务
    	return require("gateLib"):callPlayer(kid, accountId, "getDistinctId")
    end
end


--[[
    写运营日志(事件日志)
    @accountId      账号ID, 传玩家ID
    @logName        日志名称, 见 gLogEvent 定义
    @logData        日志数据
    eg:
        logLib:writeLog4Gm(19000, "payment", {["#ip"] = "192.168.1.1", OrderId = "abc_123", Product_Name = "月卡", Price = 30,})
]]
function logLib:writeLog4Gm(accountId, logName, logData)
	if not accountId or not logName or not logData then
		gLog.e("logLib:writeLog4Gm error", accountId, logName, logData)
	end
	self:send("writeLog4Gm", accountId, self:addLogCommInfo(accountId, logData), logName, logData)
end

--[[
    设置玩家属性, 重复设置时后者覆盖前者
]]
function logLib:setUserPro4Gm(accountId, properties)
	if not accountId then
		gLog.e("logLib:setUserPro4Gm error", accountId, properties)
	end
	self:send("setUserPro4Gm", accountId, self:getDistinctId(accountId), properties)
end

--[[
    只设置玩家属性一次, 重复设置时后者不会覆盖前者
]]
function logLib:setUserProOnce4Gm(accountId, properties)
	if not accountId then
		gLog.e("logLib:setUserProOnce4Gm error", accountId, properties)
	end
	self:send("setUserProOnce4Gm", accountId, self:getDistinctId(accountId), properties)
end

--[[
	累加玩家属性
]]
function logLib:addUserPro4Gm(accountId, properties)
	if not accountId then
		gLog.e("logLib:addUserPro4Gm error", accountId, properties)
	end
	self:send("addUserPro4Gm", accountId, self:getDistinctId(accountId), properties)
end

--[[
	扩展玩家数组类型的属性
]]
function logLib:appendUserPro4Gm(accountId, properties)
	if not accountId then
		gLog.e("logLib:appendUserPro4Gm error", accountId, properties)
	end
	self:send("appendUserPro4Gm", accountId, self:getDistinctId(accountId), properties)
end

--[[
	清除玩家部分属性
]]
function logLib:unsetUserPro4Gm(accountId, properties)
	if not accountId then
		gLog.e("logLib:unsetUserPro4Gm error", accountId, properties)
	end
	self:send("unsetUserPro4Gm", accountId, self:getDistinctId(accountId), properties)
end

--[[
	删除玩家属性数据(慎用)
]]
function logLib:delUserPro4Gm(accountId)
	if not accountId then
		gLog.e("logLib:delUserPro4Gm error", accountId)
	end
	self:send("delUserPro4Gm", accountId, self:getDistinctId(accountId))
end
-------------------------------------------------数数日志结束-------------------------------------------------<<<

-------------------------------------------------中台日志开始------------------------------------------------->>>
-- 写中台运营日志
function logLib:writeLog4Zt(event_tag, logData)
	if not event_tag or not gLogEventTagZt[event_tag] or not logData or not next(logData) then
		gLog.e("logLib:writeLog4Zt error", logData)
		return
	end
	logData.event_tag = event_tag
	self:send("writeLog4Zt", logData)
end
-------------------------------------------------中台日志结束-------------------------------------------------<<<

return logLib
