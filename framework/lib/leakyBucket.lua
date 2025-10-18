--[[
    排队削峰-fake漏桶算法
]]
local leakyBucket = class("leakyBucket")

function leakyBucket:ctor()
    -- 桶容量
    self.maxVolume = 10000
    -- 流出速率
    self.maxOutSpeed = 2000
    -- 当前容量
    self.volume = 0
    -- 当前流出量
    self.stream = 0
end

-- 设置桶容量
function leakyBucket:setMaxVolume(maxVolume)
    if maxVolume then
        self.maxVolume = maxVolume
    end
end

-- 设置流出速率
function leakyBucket:setMaxOutSpeed(maxOutSpeed)
    if maxOutSpeed then
        self.maxOutSpeed = maxOutSpeed
    end
end
 
-- 流入一滴水
function leakyBucket:inputWater()
    if (self.volume < self.maxVolume) then
        self.volume = self.volume + 1
        return true
    end
    return false
end

-- 流出一滴水, 添加一滴当前流出量
function leakyBucket:outputWater()
    if (self.volume > 0) then
        if (self.stream < self.maxOutSpeed) then
            self.stream = self.stream + 1
            self.volume = self.volume - 1
            return true
        end
        return false
    end
    gLog.e("leakyBucket:outputWater error")
    return false
end

-- 任务完成减少流量
function leakyBucket:outSuccess()
    self.stream = self.stream - 1
end

return leakyBucket