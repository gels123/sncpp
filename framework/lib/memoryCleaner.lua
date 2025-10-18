--[[
  数据清理器
]]
local skynet = require ("skynet")
local skynetQueue = require ("skynet.queue")
local zset = require("zset")
local memoryCleaner = class("memoryCleaner")

--构造函数
function memoryCleaner:ctor()
    self.sq = nil           --串行队列

    self.cleanInterval = 13 * 60     --清理间隔, 默认13分钟

    self.objectAliveTime = 26 * 60   --对象存活时间, 默认26分钟

    self.objectAliveRef = zset.new() --对象KEY-存活截止时间集

    self:cleanMemory()               --清理内存
end

--获取串行队列
function memoryCleaner:getSq()
    if not self.sq then
        self.sq = skynetQueue()
    end
    return self.sq
end

--设置清理间隔
function memoryCleaner:setCleanInterval(time)
    if time and time > 0 then
        self.cleanInterval = time
    end
end

--设置对象存活时间
function memoryCleaner:setObjectAliveTime(time)
    if time and time > 0 then
        self.objectAliveTime = time
    end
end

--更新对象存活截止时间
function memoryCleaner:updateObjectTime(key)
    local deadTime = svrFunc.systemTime() + self.objectAliveTime
    self.objectAliveRef:add(deadTime, tostring(key))
end

--清理内存
function memoryCleaner:cleanMemory()
    -- gLog.d("==memoryCleaner:cleanMemory start==")
    xpcall(function ()
        --遍历对象KEY-存活截止时间关联, 清理过期数据
        local cnt = self.objectAliveRef:count()
        if cnt <= 0 then
            return
        end
        local curTime = svrFunc.systemTime()
        local opt = 1
        while (cnt > 0) do
            local ranges = self.objectAliveRef:range(1, 1)
            local key = ranges and ranges[1]
            if not key then
                break
            end
            local deadTime = tonumber(self.objectAliveRef:score(key))
            if not deadTime or deadTime > curTime then
                break
            end
            local ok = self:cleanMemoryObj(key)
            if not ok then
                gLog.e("memoryCleaner:cleanMemory error", self.class.__cname)
                break
            end
            self.objectAliveRef:rem(tostring(key))
            cnt = self.objectAliveRef:count()

            opt = opt + 1
            if opt%500 == 0 then
                skynet.sleep(100)
            end
        end
    end, svrFunc.exception)
    -- gLog.d("==memoryCleaner:cleanMemory end==")

    skynet.timeout(self.cleanInterval * 100, handler(self, self.cleanMemory))
end

--清理一个内存中的对象(子类需重载该方法)
function memoryCleaner:cleanMemoryObj(key)
    return false 
end

return memoryCleaner

