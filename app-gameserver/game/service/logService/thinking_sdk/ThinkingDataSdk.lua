--LuaSDK
local Util = require "thinking_sdk.Util"
local isDebug = dbconf.DEBUG

local function class(base, _ctor)
    local c = {}
    if not _ctor and type(base) == 'function' then
        _ctor = base
        base = nil
    elseif type(base) == 'table' then
        for i, v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    c.__index = c
    local mt = {}
    mt.__call = function(_, ...)
        local obj = {}
        setmetatable(obj, c)
        if _ctor then
            _ctor(obj, ...)
        end
        return obj
    end
    c._ctor = _ctor
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then
                return true
            end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

--SDK
TdSDK = class(function(self, consumer)
    if consumer == nil or type(consumer) ~= "table" then
        error("consumer参数不正确.")
    end
    self.consumer = consumer
    self.superProperties = {}
end)

--DebugConsumer
TdSDK.DebugConsumer = class(function(self, url, appid, debugOnly)
    if appid == nil or type(appid) ~= "string" or string.len(appid) == 0 then
        error("appid不能为空.")
    end
    if url == nil or type(url) ~= "string" or string.len(url) == 0 then
        error("上报地址不能为空.")
    end
    self.url = url .. "/data_debug"
    self.appid = appid
    self.debugOnly = debugOnly
end)
function TdSDK.DebugConsumer:add(msg)
    if (msg == nil) then
        Util.log("Error: ", "数据为空！")
        return false
    end
    local returnCode, code = Util.post(self.url, self.appid, msg, true, self.debugOnly)
    Util.log("Info: ", "同步发送到: " .. self.url .. " 返回Code:[" .. code .. "]\nBody: " .. Util.toJson(msg) .. "\n返回: " .. returnCode)
    if (returnCode == 0) then
        return true
    end
    return false
end
function TdSDK.DebugConsumer:flush()
end
function TdSDK.DebugConsumer:close()
end
function TdSDK.DebugConsumer:toString()
    return "\n--Consumer: DebugConsumer" ..
            "\n--Consumer.Url: " .. self.url ..
            "\n--Consumer.Appid: " .. self.appid
end

--BatchConsumer
TdSDK.BatchConsumer = class(function(self, url, appid, batchNum, cacheCapacity)
    if appid == nil or type(appid) ~= "string" or string.len(appid) == 0 then
        error("appid不能为空。")
    end
    if url == nil or type(url) ~= "string" or string.len(url) == 0 then
        error("上报地址不能为空。")
    end
    if batchNum ~= nil and type(batchNum) ~= "number" then
        error("批量条数应该为Number类型。")
    end
    self.url = url .. "/sync_server"
    self.appid = appid
    self.batchNum = batchNum or TdSDK.batchNumber
    self.eventArrayJson = {}
    self.cacheCapacity = cacheCapacity or TdSDK.cacheCapacity
    self.cacheTable = {}
end)
function TdSDK.BatchConsumer:add(msg)
    if (msg == nil) then
        Util.log("Error: ", "数据为空！")
        return false
    end
    local num = #self.eventArrayJson + 1
    self.eventArrayJson[num] = msg
    if (num >= self.batchNum or #self.cacheTable > 0) then
        return self:flush()
    end
    return true
end
function TdSDK.BatchConsumer:flush(flag)
    if #self.eventArrayJson == 0 and #self.cacheTable == 0 then
        return true
    end
    if (flag or #self.eventArrayJson >= self.batchNum or #self.cacheTable == 0) then
        local events = self.eventArrayJson
        self.eventArrayJson = {}
        table.insert(self.cacheTable, events)
    end
    while (#self.cacheTable > 0)
    do
        local events = self.cacheTable[1]
        if isDebug then
            gLog.d("TdSDK.BatchConsumer:flush gm log", events)
        end
        local returnCode, code = Util.post(self.url, self.appid, events)
        if (code == 200) then
            table.remove(self.cacheTable, 1)
        else
            if (#self.cacheTable > self.cacheCapacity) then
                table.remove(self.cacheTable, 1)
            end
            return false
        end
        if (not flag) then
            if (returnCode ~= 0) then
                return false
            else
                return true
            end
        end
    end

    return true
end
function TdSDK.BatchConsumer:close()
    return self:flush(true)
end
function TdSDK.BatchConsumer:toString()
    return "\n--Consumer: BatchConsumer" ..
            "\n--Consumer.Url: " .. self.url ..
            "\n--Consumer.Appid: " .. self.appid ..
            "\n--Consumer.BatchNum: " .. self.batchNum
end

--LogConsumer
TdSDK.LogConsumer = class(function(self, logPath, rule, batchNum, fileSize, fileNamePrefix)
    if logPath == nil or type(logPath) ~= "string" or string.len(logPath) == 0 then
        error("日志目录不能为空.")
    end
    if rule ~= nil and type(rule) ~= "string" then
        error("文件名规则参数错误.")
    end

    if batchNum ~= nil and type(batchNum) ~= "number" then
        error("批量条数应该为Number类型.")
    end
    self.rule = rule or TdSDK.LOG_RULE.DAY
    self.logPath = Util.mkdirFolder(logPath)
    self.fileNamePrefix = fileNamePrefix
    self.fileSize = fileSize
    self.count = nil
    self.batchNum = batchNum or TdSDK.batchNumber
    self.currentFileTime = os.date("%Y-%m-%d %H:%M:%S")
    self.fileName = Util.getFileName(logPath, fileNamePrefix, self.rule)
    self.eventArrayJson = {}
    Util.log("Info: ", "LogConsumer生效, 日志目录为: " .. self.logPath .. " 文件切分方式: " .. self.rule)
end)
function TdSDK.LogConsumer:add(msg)
    local num = #self.eventArrayJson + 1
    self.eventArrayJson[num] = msg
    if (num >= self.batchNum) then
        self:flush()
    end
    return num
end
function TdSDK.LogConsumer:flush()
    if #self.eventArrayJson == 0 then
        return true
    end
    local isFileNameChange = false
    if self.rule == TdSDK.LOG_RULE.HOUR then
        isFileNameChange = Util.getDateFromDateTime(self.currentFileTime) ~= os.date("%Y-%m-%d")
                or Util.getHourFromDate(self.currentFileTime) ~= Util.getCurrentHour()
    else
        isFileNameChange = Util.getDateFromDateTime(self.currentFileTime) ~= os.date("%Y-%m-%d")
    end

    if isFileNameChange then
        self.currentFileTime = os.date("%Y-%m-%d %H:%M:%S")
        self.fileName = Util.getFileName(self.logPath, self.fileNamePrefix, self.rule)
        self.count = nil
    end
    if self.fileSize and self.fileSize > 0 then
        self.count = Util.getFileCount(self.fileName, self.fileSize, self.count)
    end
    local fileName = self.fileName
    if self.count then
        fileName = self.fileName .. "_" .. self.count
    end
    local result = Util.writeFile(fileName, self.eventArrayJson)
    if (result) then
        self.eventArrayJson = {}
    end
    return true
end
function TdSDK.LogConsumer:close()
    self:flush()
end
function TdSDK.LogConsumer:toString()
    return "\n--Consumer: LogConsumer" ..
            "\n--Consumer.LogPath: " .. self.logPath ..
            "\n--Consumer.Rule: " .. self.rule ..
            "\n--Consumer.BatchNum: " .. self.batchNum
end

--[[
     * 注册公共属性,注册后每次发送的消息体中都包含该属性值
     * @param params 属性
--]]
function TdSDK:setSuperProperties(params)
    local ok, ret = pcall(checkKV, params)
    if not ok then
        Util.log("Error: ", "注册公共属性错误: ", ret)
    else
        if (type(params) == "table") then
            self.superProperties = Util.mergeTables(self.superProperties, params)
        end
    end
end
function TdSDK:setSuperProperty(key, value)
    print(key)
    if (key ~= nil) then
        local params = {}
        params[key] = value
        print(params[key])
        self:setSuperProperties(params)
    end
end
--[[
     * 移除公共属性
     * @param key 属性Key
--]]
function TdSDK:removeSuperProperty(key)
    self.superProperties[key] = nil
end
--[[
     * 获取公共属性
     * @param key 属性Key
     * @return 该KEY的公共属性值
--]]
function TdSDK:getSuperProperty(key)
    Util.log("", "获取公共属性" .. key .. "值为: " .. self.superProperties[key])
    return self.superProperties[key]
end
--[[
     * 获取公共属性
     * @return 所有公共属性
--]]
function TdSDK:getSuperProperties()
    return self.superProperties
end
--清除公共属性
function TdSDK:clearSuperProperties()
    self.superProperties = {}
end

--[[
     * 设置用户的属性
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param properties 事件属性
--]]
function TdSDK:userSet(accountId, distinctId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_set", nil, nil, properties)
    if ok then
        Util.log("Info: ", "调用userSet方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userSet方法错误: ", ret)
    end
end
--[[
     * 首次设置用户的属性,该属性只在首次设置时有效
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param properties 事件属性
--]]
function TdSDK:userSetOnce(accountId, distinctId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_setOnce", nil, nil, properties)
    if ok then
        Util.log("Info: ", "调用userSetOnce方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userSetOnce方法错误: ", ret)
    end
end
--[[
     * 为用户的一个或多个数值类型的属性累加一个数值
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param properties 事件属性
--]]
function TdSDK:userAdd(accountId, distinctId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_add", nil, nil, properties)
    if ok then
        Util.log("Info: ", "调用userAdd方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userAdd方法错误: ", ret)
    end
end
--[[
     * 追加用户列表类型的属性
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param properties 事件属性
--]]
function TdSDK:userAppend(accountId, distinctId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_append", nil, nil, properties)
    if ok then
        Util.log("Info: ", "调用userAppend方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userAppend方法错误: ", ret)
    end
end
--[[
     * 删除用户属性
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param properties 事件属性
--]]
function TdSDK:userUnset(accountId, distinctId, properties)
    local unSetProperties = {}
    for key, _ in pairs(properties) do
        unSetProperties[properties[key]] = 0
    end
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_unset", nil, nil, unSetProperties)
    if ok then
        Util.log("Info: ", "调用userUnSet方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userUnSet方法错误: ", ret)
    end
end
--[[
     * 删除用户
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
--]]
function TdSDK:userDel(accountId, distinctId)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "user_del", nil, nil, {})
    if ok then
        Util.log("Info: ", "调用userDelete方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用userDelete方法错误: ", ret)
    end
end

--[[
     * 事件数据
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param eventName 事件名称
     * @param properties 事件属性
--]]
function TdSDK:track(accountId, distinctId, eventName, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "track", eventName, "", properties, self.superProperties)
    if ok then
        Util.log("Info: ", "调用track方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用track方法错误: ", ret)
    end
end
--[[
     * 更新旧属性值
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param eventName 事件名称
     * @param eventId 事件ID
     * @param properties 事件属性
--]]
function TdSDK:trackUpdate(accountId, distinctId, eventName, eventId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "track_update", eventName, eventId, properties, self.superProperties)
    if ok then
        Util.log("Info: ", "调用track_update方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用track_update方法错误: ", ret)
    end
end
--[[
     * 覆盖所有旧属性
     * @param distinctId 未登录用户ID
     * @param accountId 登录用户ID
     * @param eventName 事件名称
     * @param eventId 事件ID
     * @param properties 事件属性
--]]
function TdSDK:trackOverwrite(accountId, distinctId, eventName, eventId, properties)
    local ok, ret = pcall(upload, self.consumer, distinctId, accountId, "track_overwrite", eventName, eventId, properties, self.superProperties)
    if ok then
        Util.log("Info: ", "调用track_overwrite方法: 成功")
        return ret
    else
        Util.log("Error: ", "调用track_overwrite方法错误: ", ret)
    end
end

--[[
     * 上传数据,首先校验相关KEY和VALUE,符合规则才可以上传
     * @param consumer 收集器
     * @param distinctId 用户标识
     * @param isLogin 是否登陆
     * @param eventName 事件名称
     * @param eventId 事件ID，结合eventName用于track_update和track_overwrite
     * @param properties 属性
     * @param super 公共属性
--]]
function upload(consumer, distinctId, accountId, eventType, eventName, eventId, properties, superProperties)
    local finalProperties, presetProperties = divide(properties)
    check(distinctId, accountId, eventType, eventName, eventId, finalProperties)

    local eventJson = {}
    if accountId ~= nil and string.len(accountId) ~= 0 then
        eventJson["#account_id"] = tostring(accountId)
    end
    if distinctId ~= nil and string.len(distinctId) ~= 0 then
        eventJson["#distinct_id"] = tostring(distinctId)
    end
    eventJson["#type"] = eventType
    if eventName ~= nil and string.len(eventName) ~= 0 then
        eventJson["#event_name"] = tostring(eventName)
    end
    if eventId ~= nil and string.len(eventId) ~= 0 then
        eventJson["#event_id"] = tostring(eventId)
    end
    --预置属性
    for key, value in pairs(presetProperties) do
        eventJson[key] = value
    end
    if presetProperties["#time"] == nil then
        eventJson["#time"] = os.date("%Y-%m-%d %H:%M:%S")
    end

    local mergeProperties = {}
    mergeProperties = Util.mergeTables(mergeProperties, superProperties)
    mergeProperties = Util.mergeTables(mergeProperties, finalProperties)
    if eventType == "track" or eventType == "track_update" or eventType == "track_overwrite" then
        mergeProperties["#lib"] = TdSDK.platForm
        mergeProperties["#lib_version"] = TdSDK.version
    end
    eventJson["properties"] = mergeProperties
    local ret = consumer:add(eventJson)
    presetProperties = nil
    finalProperties = nil
    mergeProperties = nil
    eventJson = nil
    return ret
end

function divide(properties)
    local presetProperties = {}
    local finalProperties = {}
    for key, value in pairs(properties) do
        if (key == "#ip" or key == "#uuid" or key == "#first_check_id" or key == "#time" or key == "#app_id") then
            presetProperties[key] = value
        else
            finalProperties[key] = value
        end
    end
    return finalProperties, presetProperties
end

function check(distinctId, accountId, eventType, eventName, eventId, properties)
    assert(distinctId == nil or type(distinctId) == "string" or type(distinctId) == "number", "distinctId参数应该为数字或字符串")
    assert(accountId == nil or type(accountId) == "string" or type(accountId) == "number", "accountId参数应该为数字或字符串")
    assert(type(eventType) == "string", "type参数应该为字符串类型")
    assert(eventName == nil or type(eventName) == "string", "eventName应该为字符串类型")
    assert(type(properties) == "table", "properties应该为Table类型")
    --校验字段
    if ((distinctId == nil or string.len(distinctId) == 0) and (accountId == nil or string.len(accountId) == 0)) then
        error("distinctId和accountId不能同时为空！")
    end
    if (Util.startWith(eventType, "track") and (eventName == nil or string.len(eventName) == 0)) then
        error("type为track、track_update或track_overwrite时，eventName不能为空！")
    end
    if ((eventType == "track_update" or eventType == "track_overwrite") and (eventId == nil or string.len(eventId) == 0)) then
        error("type为track_update或track_overwrite时，eventId不能为空！")
    end
    checkKV(properties, eventName)
end

function checkKV(properties, eventName)
    --校验K/V
    local userAdd = "user_add"
    local userUnset = "user_unset"
    for key, value in pairs(properties) do
        if (string.len(key) == 0) then
            Util.log("Warn: ", "The property key is empty")
        end
        if (type(value) ~= "string" and
                type(value) ~= "number" and
                type(value) ~= "boolean" and
                type(value) ~= "table") then
            Util.log("Warn: ", "The property " .. key .. " is not number, string, boolean, table.")
        end
        if (type(value) == "table") then
            for k, v in pairs(value) do
                if (type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean") then
                    Util.log("Warn: ", "The table property " .. k .. " is not number, string, boolean.")
                end
            end
        end
        if (type(value) == "string" and string.len(value) == 0 and not (userUnset == eventName)) then
            Util.log("Warn: ", "The property " .. key .. " string value is null or empty")
        end

        if (userAdd == eventName and type(value) ~= "number") then
            Util.log("Warn: ", "The property value of " .. key .. " should be a number ")
        end
    end
end

function TdSDK:flush()
    self.consumer:flush()
end

function TdSDK:close()
    self.consumer:close()
end

function TdSDK:toString()
    return self.consumer:toString()
end

TdSDK.platForm = "Lua"
TdSDK.version = "1.2.0"
TdSDK.batchNumber = 20
TdSDK.cacheCapacity = 50
TdSDK.logModePath = "."

TdSDK.LOG_RULE = {}
TdSDK.LOG_RULE.HOUR = "%Y-%m-%d-%H"
TdSDK.LOG_RULE.DAY = "%Y-%m-%d"
return TdSDK
