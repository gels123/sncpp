--[[
    安全执行任务
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local safeProc = class("safeProc")

function safeProc:ctor()
    self.task = {}
end

-- 添加安全任务
function safeProc:safe(f, ...)
    assert(type(f) == "function")
    local ok = xpcall(f, svrFunc.exception, ...)
    if not ok then
        table.insert(self.task, {f = f, args = {...}})
    end
end

-- 等待所有任务执行结束
function safeProc:retry()
    if next(self.task) then
        local cnt = #self.task
        while (cnt > 0) do
            cnt = cnt - 1
            local v = table.remove(self.task, 1)
            self:safe(v.f, table.unpack(v.args))
        end
    end
end

return safeProc