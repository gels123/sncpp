--[[
    http请求封装
]]
local skynet = require("skynet")
local httpc = require "http.httpc"
local svrFunc = require("svrFunc")
local json = require("json")
local httpLib = class("httpLib")

httpc.timeout = 500	-- set timeout 5 second

function httpLib:escape(s)
    return string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

-- 执行请求
-- @method  "GET" 或 "POST"
-- @eg: local code, ret = self:httpReq("GET", "https://dev-xxx.xxx/", "/user/device/login", {a=1})
function httpLib:httpReq(method, host, url, form, recvheader, header, content)
    header["content-type"] = "application/json"
    if method == "GET" then
        local body = {}
        if form then
            for k,v in pairs(form) do
                table.insert(body, string.format("%s=%s", self:escape(k), self:escape(v)))
            end
        end
        if not table.empty(body) then
            url = url .. "?" .. table.concat(body , "&")
        end
        gLog.i("httpLib:httpReq=", host..url)
        -- 第一次
        local ok, code, ret = xpcall(httpc.request, svrFunc.exception, method, host, url, recvheader, header, content)
        if ok then
            return code, ret
        end
        -- 第二次
        ok, code, ret = xpcall(httpc.request, svrFunc.exception, method, host, url, recvheader, header, content)
        return code, ret
    else
        gLog.i("httpLib:httpReq=", host..url)
        local ok, code, ret = xpcall(httpc.request, svrFunc.exception, method, host, url, recvheader, header, json.encode(content))
        if ok then
            return code, ret
        end
        local ok, code, ret = xpcall(httpc.request, svrFunc.exception, method, host, url, recvheader, header, json.encode(content))
        return code, ret
    end
end

return httpLib
