--[[
    日志管理器
]]
local skynet = require("skynet")
local md5 = require("md5")
local curl = require "luacurl"
local json = require "json"
local logCenter = require("logCenter"):shareInstance()
local logMgr = class("logMgr")

-- 构造
function logMgr:ctor()
    -- 批量发送条数
    self.batchNum = 10
    -- 批量发送时间间隔
    self.timeInv = 30
    -- 批量发送计时器Id
    self.timerId = nil
    -- 发送状态:0=初始,1=网络联通可以发送,2=断网
    self.writeStatus = 0
    -- 日志消息队列
    self.queue = {}
end

-- 初始化
function logMgr:init()
    -- 批量发送计时器
    self.timerId = logCenter.myTimer:schedule(handler(self, self.timerCallback), svrFunc.systemTime() + self.timeInv)
end

-- 关服
function logMgr:close()
    if self.timerId then
        logCenter.myTimer:stop(self.timerId)
    end
    if #self.queue > 0 then
        self:writeLogBatch()
    end
    if self.cIns then
        self.cIns:close()
    end
end

-- 写中台运营日志
function logMgr:writeLog4Zt(logData)
    gLog.d("logMgr:writeLog4Zt logData=", logData, #self.queue)
    if not logData then
        gLog.e("logMgr:writeLog4Zt error, logData=", logData)
        return
    end
    table.insert(self.queue, logData)
    if #self.queue >= self.batchNum then
        logCenter.myTimer:reset(self.timerId, svrFunc.systemTime() + self.timeInv)
        self:writeLogBatch()
    end
end

-- 计时器回调
function logMgr:timerCallback(data)
    -- gLog.d("==logMgr:timerCallback==")
    self.timerId = logCenter.myTimer:schedule(handler(self, self.timerCallback), svrFunc.systemTime() + self.timeInv)
    if #self.queue > 0 then
        self:writeLogBatch()
    end
end

-- 批量上报日志
function logMgr:writeLogBatch()
    local data = self.queue
    self.queue = {}
    self:writeLogHttp(data)
end

-- 执行上报日志
function logMgr:writeLogHttp(data)
    -- HTTP POST
    if not self.cIns then
        self.cIns = curl.easy()
        self.cIns:setopt(curl.OPT_TIMEOUT, 2)
        self.cIns:setopt(curl.OPT_POST, true)
        self.cIns:setopt(curl.OPT_WRITEFUNCTION, function(userparam, t)
            gLog.d("logMgr:writeLogHttp ret=", userparam, t)
        end)
    end
    -- http://10.7.69.177:64430/log?app_id=demo.global.development&timestamp=1620972944605&signature=56baf6252fd3248e9aeb5911c4f044ac&num=2
    local timestamp = svrFunc.systemTime()
    local url = string.format('%s?app_id=%s&timestamp=%d&signature=%s&num=%d', dbconf.log4ZtUrl, dbconf.log4ZtAppID, timestamp, self:createSign(dbconf.log4ZtAppID, dbconf.log4ZtAppKey, timestamp), #data)
    local strdata = json.encode(data)
    self.cIns:setopt(curl.OPT_URL, url)
    self.cIns:setopt(curl.OPT_POSTFIELDS, strdata)
    local ok, err = self.cIns:perform()
    gLog.d("logMgr:writeLogHttp perform=", ok, err)
    if not ok then
        --gLog.e("logMgr:writeLogHttp perform error=", ok, err)
        self.writeStatus = 2
        logCenter.logFileWriter:writeFile(strdata)
    else
        if self.writeStatus == 0 then
            self.writeStatus = 1
        elseif self.writeStatus == 2 then
            -- 断网=>网络联通, 读取异常处理文件并重发
            self.writeStatus = 1
            logCenter.logFileWriter:loadFile()
        end
    end
end

-- 获取签名(md5信息摘要)
function logMgr:createSign(appId, key, timestamp)
    return md5.sumhexa (string.format("%s:%s:%s", appId, key, timestamp))
end

return logMgr