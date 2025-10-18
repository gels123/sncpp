--- 补偿事务
--- 如果事务执行失败，按执行顺序反向执行补偿事务
--- 如果事务执行中出现异常，触发异常的当前事务不会被执行补偿
local compTransaction = class("compTransaction")
local skynetQueue = require "skynet.queue"

function compTransaction:ctor()
    self.tranMap = {}
    self.compMap = {}
    self.lastIndex = 0
    self.exceptionFlag = false
    self.sq = skynetQueue()
end

--- 添加事务
function compTransaction:add(transactionFunc, compensatingFunc)
    assert(transactionFunc, "param transactionFunc is nil")
    self.sq(function()
        table.insert(self.tranMap, transactionFunc)
        if compensatingFunc then
            self.compMap[#self.tranMap] = compensatingFunc
        end
    end)
end

--- 执行事务
function compTransaction:run()
    self.sq(function()
        local ok, ret = xpcall(function()
            for index = 1, #self.tranMap do
                local isSeccess = self.tranMap[index]()
                self.lastIndex = index
                if not isSeccess then
                    local compResult = self:compensating()
                    return false, compResult
                end
            end
            return true
        end, svrFunc.error)
        if not ok then
            self.exceptionFlag = true
            local compResult = self:compensating()
            return false, compResult
        else
            return ret
        end
    end)
end

--- 执行补偿
function compTransaction:compensating()
    local compResult = {
        lastIndex = self.lastIndex,
        transactionException = self.exceptionFlag,
        compensatingException = {},
    }
    for index = self.lastIndex, 1, -1 do
        local ok = xpcall(function()
            self.compMap[index]()
        end, svrFunc.error)
        if not ok then
            compResult.compensatingException[index] = true
        end
    end
    return compResult
end

function compTransaction:clear()
    self.sq(function()
        self.tranMap = {}
        self.compMap = {}
        self.lastIndex = 0
        self.busyFlag = false
        self.exceptionFlag = false
    end)
end

