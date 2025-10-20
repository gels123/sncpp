--[[
    日志打点服务中心
]]
local skynet = require "skynet"
local dbconf = require "dbconf"
--local TdSDK = require "thinking_sdk.ThinkingDataSdk"
local serviceCenterBase = require("serviceCenterBase2")
local logCenter = class("logCenter", serviceCenterBase)

function logCenter:ctor()
    logCenter.super.ctor(self)
end

function logCenter:init(kid)
    gLog.i("==logCenter:init begin==", kid)
    self.super.init(self, kid)

    -- 日志管理器
    --self.logMgr = require("logMgr").new()
    ---- 写日志异常处理文件
    --self.logFileWriter = require("logFileWriter").new()

    -- 初始化日志管理器
    --self.logMgr:init()
    --self.logFileWriter:init(dbconf.log4ZtFilePath)

    -- SDK实例
    --local consumer = nil
    --if true then
    --    consumer = TdSDK.LogConsumer(dbconf.log4FilePath, TdSDK.LOG_RULE.DAY, dbconf.log4GmBatchNumber, 1024, "gamelog") -- 批量写本地文件
    --else
    --    consumer = TdSDK.BatchConsumer(dbconf.log4GmUrl, dbconf.log4GmAppID, dbconf.log4GmBatchNumber, dbconf.log4GmCacheCapacity) -- 批量向 TA 服务器传输数据
    --end
    --self.sdk = TdSDK(consumer)

    -- 设置公共属性
    -- self:setSuperProperties({
    --     kid = self.kid,
    -- })

    -- 测试
    -- if true then
    --     local logData = {}
    --     logData["productNames"] = { "Lua入门", "Lua从精通到放弃" }
    --     logData["productType"] = "Lua书籍"
    --     logData["producePrice"] = 80
    --     logData["shop"] = "xx网上书城"
    --     self.sdk:track("ABC_DEF", 125445, "ViewProduct", logData)
    -- end

    gLog.i("==logCenter:init end==", kid)
end

-- 停止服务
function logCenter:stop()
    gLog.i("==logCenter:stop begin==", self.kid)
    self.super.stop(self)

    if self.sdk then
        self.sdk:flush()
        self.sdk:close()
    end

    if self.logMgr then
        self.logMgr:close()
    end
    gLog.i("==logCenter:stop end==", self.kid)
end

-------------------------------------------------数数日志开始------------------------------------------------->>>
--[[
    设置公共属性
]]
function logCenter:setSuperProperties(properties)
    if properties and next(properties) then
        self.sdk:setSuperProperties(properties)
    else
        gLog.w("logCenter:setSuperProperties error", properties)
    end
end

--[[
    写运营日志(事件日志)
    @accountId      账号ID, 传玩家ID
    @distinctId     访客ID
    @logName        日志名称
    @logData        日志数据
]]
function logCenter:writeLog4Gm(accountId, distinctId, logName, logData)
    if not dbconf.log4GmOn then
        return
    end 
    if dbconf.DEBUG then
        gLog.d("logCenter:writeLog4Gm accountId=", accountId, "distinctId=", distinctId, "logName=", logName, "logData=", logData)
    end
    self.sdk:track(accountId, distinctId, logName, logData)
end

--[[
    设置玩家属性, 重复设置时后者覆盖前者
]]
function logCenter:setUserPro4Gm(accountId, distinctId, properties)
    if not dbconf.log4GmOn then
        return
    end
    if accountId and properties and next(properties) then
        self.sdk:userSet(accountId, distinctId, properties)
    else
        gLog.w("logCenter:userSet error", accountId, distinctId, properties)
    end
end

--[[
    只设置玩家属性一次, 重复设置时后者不会覆盖前者
]]
function logCenter:setUserProOnce4Gm(accountId, distinctId, properties)
    if not dbconf.log4GmOn then
        return
    end
    if accountId and properties and next(properties) then
        self.sdk:userSetOnce(accountId, distinctId, properties)
    else
        gLog.w("logCenter:userSetOnce error", accountId, distinctId, properties)
    end
end

--[[
    累加玩家属性
]]
function logCenter:addUserPro4Gm(accountId, distinctId, properties)
    if not dbconf.log4GmOn then
        return
    end 
    if accountId and properties and next(properties) then
        self.sdk:userAdd(accountId, distinctId, properties)
    else
        gLog.w("logCenter:userAdd error", accountId, distinctId, properties)
    end
end

--[[
    扩展玩家数组类型的属性
]]
function logCenter:appendUserPro4Gm(accountId, distinctId, properties)
    if not dbconf.log4GmOn then
        return
    end
    if accountId and properties and next(properties) then
        self.sdk:userAppend(accountId, distinctId, properties)
    else
        gLog.w("logCenter:userAppend error", accountId, distinctId, properties)
    end
end

--[[
    清除玩家部分属性
]]
function logCenter:unsetUserPro4Gm(accountId, distinctId, properties)
    if not dbconf.log4GmOn then
        return
    end
    if accountId and properties and next(properties) then
        self.sdk:userUnset(accountId, distinctId, properties)
    else
        gLog.w("logCenter:userUnset error", accountId, distinctId, properties)
    end
end

--[[
    删除玩家属性数据(慎用)
]]
function logCenter:delUserPro4Gm(accountId, distinctId)
    if not dbconf.log4GmOn then
        return
    end
    if accountId then
        self.sdk:userDel(accountId, distinctId)
    else
        gLog.w("logCenter:userDel error", accountId, distinctId)
    end
end
-------------------------------------------------数数日志结束-------------------------------------------------<<<

--[[
    设置日志上报开关
]]
function logCenter:switchLog4GmOn(isOn)
    dbconf.log4GmOn = isOn and true or false
end

-------------------------------------------------中台日志开始------------------------------------------------->>>
-- 写中台运营日志
function logCenter:writeLog4Zt(logData)
    if logData then
        self.logMgr:writeLog4Zt(logData)
    end
end
-------------------------------------------------中台日志结束-------------------------------------------------<<<

return logCenter
