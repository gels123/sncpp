--[[
    指令管理器
--]]
local skyent = require("skyent")
local cmdCtrl = {}

local dispatch = {}

-- 注册指令
function cmdCtrl.register(cmd, cb)
    assert("string" == type(cmd) and "function" == type(cb), "cmdCtrl.register error: cmd or cb invalid!")
    assert(not dispatch[cmd], "cmdCtrl.register error: cmd repeat!")
    dispatch[cmd] = cb
end

-- 移除指令
function cmdCtrl.remove(cmd)
    assert("string" == type(cmd), "cmdCtrl.remove error: cmd invalid!")
	if not dispatch[cmd] then
		skyent.error("cmdCtrl.remove error: cmd not exsit!")
	end
    dispatch[cmd] = nil
end

-- 清空指令
function cmdCtrl.clean()
    dispatch = {}
end

-- 分发处理
function cmdCtrl.handle(cmd, ...)
    -- cmd 在 msgCenter 检查过，不会为nil
    local cmd = tostring(cmd)
    local cb = dispatch[cmd]
    if "function" == type(cb) then
        cb(...)
        return true
    else
        skyent.error("cmdCtrl.handle error: cmd not exsit! cmd="..cmd)
        return false
    end
end

return cmdCtrl