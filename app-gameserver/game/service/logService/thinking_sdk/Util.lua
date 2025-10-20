--Tools
local _Util = {}

local socket = require("socket2")
local http = require("http2")
local ltn12 = require("ltn12")
local json = require("json")

function _Util.post(url, appid, eventArrayJson, isDebug, debugOnly)
    if not isDebug and #eventArrayJson == 0 then
        return "", ""
    end
    local request_body = toJson(eventArrayJson)
    local contentType = "application/json"
    if isDebug then
        local dryRun = 0
        if debugOnly then
            dryRun = 1
        end
        request_body = urlEncode(request_body)
        request_body = "data=" .. request_body .. "&source=server&appid=" .. appid .. "&dryRun=" .. dryRun
        contentType = "application/x-www-form-urlencoded"
    end
    local response_body = {}
    local count = 0
    local res, code
    while (count < 3)
    do
        res, code = http.request {
            url = url,
            create = function()
                local req_sock = socket.tcp()
                req_sock:settimeout(30, 't')
                return req_sock
            end,
            method = "POST",
            headers = {
                ["appid"] = appid;
                ["TA-Integration-Type"] = TdSDK.platForm;
                ["TA-Integration-Version"] = TdSDK.version;
                ["TA-Integration-Count"] = #eventArrayJson;
                ["Content-Type"] = contentType;
                ["Content-Length"] = #request_body;
            },
            source = ltn12.source.string(request_body),
            sink = ltn12.sink.table(response_body),
        }
        res = table.concat(response_body)
        if code ~= nil and type(code) == "number" and tonumber(code) == 200 then
            break
        end
        print("Error: Up failed,code: " .. code .. ",res: " .. res .. " data: " .. request_body)
        count = count + 1
    end
    if count >= 3 then
        return -1, code
    end
    local resultCode
    local resultJson = json.decode(res)
    if isDebug then
        resultCode = tonumber(resultJson["errorLevel"])
        if resultCode ~= 0 then
            print("Error: Up failed, result: " .. res)
        end
    else
        resultCode = tonumber(resultJson["code"])
        if resultCode ~= 0 then
            local msg = resultJson["msg"]
            if msg == nil or #msg == 0 then
                if resultCode == -1 then
                    msg = "invalid data format"
                elseif resultCode == -2 then
                    msg = "APP ID doesn't exist"
                elseif resultCode == -3 then
                    msg = "invalid ip transmission"
                else
                    msg = "Unexpected response return code"
                end
            end
            print("Error:up failed:" .. resultCode .. "，msg:" .. msg)
        end
    end

    return resultCode, code
end

function isWindows()
    local separator = package.config:sub(1, 1)
    local osName = os.getenv("OS")
    local isWindows = (separator == '\\' or (osName ~= nil and startWith(string.lower(osName), "windows")))
    return isWindows
end

function _Util.toJson(eventArrayJson)
    return json.encode(eventArrayJson)
end

function toJson(eventArrayJson)
    return json.encode(eventArrayJson)
end

function _Util.regEx(str, len)
    return string.match(str, "^(xwhat)$") ~= str and
            string.match(str, "^(xwhen)$") ~= str and
            string.match(str, "^(xwho)$") ~= str and
            string.match(str, "^(appid)$") ~= str and
            string.match(str, "^(xcontext)$") ~= str and
            string.match(str, "^(%$lib)$") ~= str and
            string.match(str, "^(%$lib_version)$") ~= str and
            string.match(str, "^[$a-zA-Z][$a-zA-Z0-9_]+$") == str and
            string.len(str) <= tonumber(len)
end

function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return string.gsub(s, " ", "+")
end

function tableIsEmpty(t)
    return _G.next(t) == nil
end

function _Util.mergeTables(...)
    local tabs = { ... }
    if not tabs then
        return {}
    end
    local origin = tabs[1]
    for i = 2, #tabs do
        if origin then
            if tabs[i] then
                for k, v in pairs(tabs[i]) do
                    origin[k] = v
                end
            end
        else
            origin = tabs[i]
        end
    end
    return origin
end

function fileExists(path)
    local retTable = { os.execute("cd " .. path) }
    local code = retTable[3] or retTable[1]
    return code == 0
end

function _Util.mkdirFolder(path)
    if (fileExists(path)) then
        return path
    end
    local isWindows = isWindows()
    local cmd = "mkdir -p " .. path
    if (isWindows) then
        cmd = "mkdir " .. path
    end
    local retTable = { os.execute(cmd) }
    local code = retTable[3] or retTable[1]
    if (code ~= 0) then
        if (isWindows) then
            return os.getenv("TEMP")
        else
            return "/tmp"
        end
    end
    return path
end

function _Util.writeFile(fileName, eventArrayJson)
    if #eventArrayJson == 0 then
        return false
    end
    local file = assert(io.open(fileName, 'a'))
    local data = ""
    for i = 1, #eventArrayJson do
        local json = toJson(eventArrayJson[i])
        data = data .. json .. "\n"
    end
    file:write(data)
    file:close()
    file = nil
    return true
end

function _Util.getFileName(filePath, fileNamePrefix, rule)
    local isWindows = isWindows()
    local separator = "/"
    if (isWindows) then
        separator = "\\"
    end
    local fileName
    if not fileNamePrefix or #fileNamePrefix == 0 then
        fileName = filePath .. separator .. "log." .. os.date(rule)
    else
        fileName = filePath .. separator .. fileNamePrefix .. ".log." .. os.date(rule)
    end

    return fileName
end

function _Util.getFileCount(fileName, fileSize, count)
    if not fileSize or fileSize <= 0 then
        return nil
    end

    if not count then
        count = 0
    end

    local result = fileName .. "_" .. count
    local file = assert(io.open(result, "a"))
    while file
    do
        local len = assert(file:seek("end"))
        if len < (fileSize * 1024 * 1024) then
            file:close()
            file = nil
        else
            count = count + 1
            result = fileName .. "_" .. count
            file = assert(io.open(result, "a"))
        end
    end
    return count
end

function _Util.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function _Util.startWith(str, substr)
    if str == nil or substr == nil then
        return false
    end
    if string.find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

function isTimeStamp(t)
    local rt = string.gsub(t, '%.', '')
    if rt == nil or string.len(rt) < 13 or tonumber(rt) == nil then
        return false
    end
    local status = pcall(function(tim)
        local number, decimal = math.modf(tonumber(tim) / 1000)
        os.date("%Y%m%d%H%M%S", number)
    end, rt)
    return status
end

function _Util.now(t)
    if t == nil or string.len(t) == 0 then
        local number, decimal = math.modf(socket.gettime() * 1000)
        return number
    end
    if (isTimeStamp(t)) then
        return t
    end
    return nil
end

function _Util.clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function _Util.printTable(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
end

--日志打印
function _Util.log(level, key, msg)
    print(level .. (key or "") .. (msg or ""))
end

--异常处理
function _Util.errorhandler(errmsg)
    print("ERROR===:", tostring(errmsg), debug.traceback())
end

function _Util.getCurrentHour()
    local t = os.date("%Y-%m-%d %H:%M:%S")
    return string.sub(t, 12, 13)
end

function _Util.getHourFromDate(dateString)
    return string.sub(dateString, 12, 13)
end

function _Util.getDateFromDateTime(dateTime)
    return string.sub(dateTime, 1, 10)
end

return _Util