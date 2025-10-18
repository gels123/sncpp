--[[
    监控 table 修改
    注意:
    1. 性能较低，建议只在测试环境中使用
    2. json.encode 因为使用了 lua_next 的 C 接口会出现无法正常序列化，需要先使用 tableMonitor.getReal() 获取原始数据
    3. 有改动 3 个系统函数: next, getmetatable, setmetatable
        防止 require 本文件时直接改动，将改动放进了 init，使用时先调用 tableMonitor.init()
    4. 测试用例见 fixtablemonitor.lua
]]
local dbconf = require("dbconf")
local tableMonitor = {}

local _open = dbconf.SAVE_DB_CHECK
local _init = false
local _real = "__real"

local _next
local _setmetatable
local _getmetatable

local rawget = rawget
local rawset = rawset
local pairs = pairs
local type = type
local stringformat = string.format

function tableMonitor.init()
    if _init then
        return
    end
    _init = true

    _next = next
    _G.next = function(t, i)
        local real = rawget(t, _real)
        if real then
            return _next(real, i)
        end
        return _next(t, i)
    end

    _setmetatable = setmetatable
    _G.setmetatable = function(t, meta)
        local real = rawget(t, _real)
        if real then
            _setmetatable(real, meta)
        else
            _setmetatable(t, meta)
        end
        return t
    end

    _getmetatable = getmetatable
    _G.getmetatable = function(t)
        local real = rawget(t, _real)
        if real then
            return _getmetatable(real)
        else
            return _getmetatable(t)
        end
    end
end

function tableMonitor.encode(t, f)
    assert("table" == type(t))
    return tableMonitor._encode("t", t, f)
end

function tableMonitor.decode(t)
    assert("table" == type(t))
    return tableMonitor._decode(t)
end

function tableMonitor.getReal(t)
    assert("table" == type(t))
    return tableMonitor._getReal(t)
end

---------------------------------------------------inner interface begin--------------------------------------------------->
-- 编码
function tableMonitor._encode(path, _t, f)
    if "table" == type(_t) then
        if rawget(_t, _real) then
            return _t
        else
            local meta = _getmetatable(_t)
            _setmetatable(_t, nil)
            local real = {}
            for k, v in pairs(_t) do
                _t[k] = nil
                real[k] = tableMonitor._encode(stringformat("%s.%s", path, k), v, f)
            end
            _setmetatable(real, meta)
            rawset(_t, _real, real)
            _t = _setmetatable(_t, {
                __index = function(t, k)
                    local real = rawget(t, _real)
                    return real[k]
                end,
                __newindex = function(t, k, v)
                    if "table" == type(v) then
                        v = tableMonitor._encode(stringformat("%s.%s", path, k), v, f)
                    end
                    local real = rawget(t, _real)
                    local old = real[k]
                    real[k] = v
                    if f and old ~= v then
                        f(path, k, v)
                    end
                end,
                __len = function(t)
                    local real = rawget(t, _real)
                    return #real
                end,
                __pairs = function(t)
                    local real = rawget(t, _real)
                    return _next, real, nil
                end,
            })
            return _t
        end
    else
        return _t
    end
end

-- 解码
function tableMonitor._decode(t)
    if "table" == type(t) then
        local real = rawget(t, _real)
        if real then
            _setmetatable(t, nil)
            local meta = _getmetatable(real)
            rawset(t, _real, nil)
            for k, v in pairs(real) do
                rawset(t, k, tableMonitor._decode(v))
            end
            _setmetatable(t, meta)
        else
            for k,v in pairs(t) do
                t[k] = tableMonitor._decode(v)
            end
        end
        return t
    else
        return t
    end
end

-- 获取原始数据
function tableMonitor._getReal(t)
    if "table" == type(t) then
        local real = rawget(t, _real)
        if real then
            local ret = {}
            for k, v in pairs(real) do
                ret[k] = tableMonitor._getReal(v)
            end
            local meta = _getmetatable(real)
            _setmetatable(ret, meta)
            return ret
        else
            local ret = {}
            for k, v in pairs(t) do
                ret[k] = tableMonitor._getReal(v)
            end
            return ret
        end
    else
        return t
    end
end
---------------------------------------------------inner interface end---------------------------------------------------<

if _open then
    tableMonitor.init()
end

return tableMonitor