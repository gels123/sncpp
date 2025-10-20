--[[
    玩家管理器
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local userC = require("user")
local roomC = require("room")
local svrAddrMgr = require("svrAddrMgr")
local lextra = require("lextra")
local frameCenter = require("frameCenter"):shareInstance()
local userMgr = class("userMgr")

-- 构造
function userMgr:ctor()
    -- 玩家列表
    self.users = {}
    -- 房间列表
    self.rooms = {}
    -- fd关联(值弱表)
    self.fdMap = {}
    setmetatable(self.fdMap, {__mode = "v"})
    -- 跑帧协程、跑帧房间
    self.co = nil
    self.gaming = {}
end

-- 获取user
function userMgr:getUser(uid, noNew)
    assert(uid)
    if not self.users[uid] and not noNew then --noNew==true, 不新建
        self.users[uid] = userC.new(uid)
    end
    return self.users[uid]
end

-- 释放user
function userMgr:delUser(uid)
    local user = self.users[uid]
    if user then
        -- 删除fd
        user:setFd(nil)
        -- 释放user
        self.users[uid] = nil
        user = nil
    end
    --gLog.dump(self, "userMgr:delUser uid="..tostring(uid))
end

-- 获取room
function userMgr:getRoom(batId, noNew)
    assert(batId)
    if not self.rooms[batId] and not noNew then --noNew==true, 不新建
        self.rooms[batId] = roomC.new(batId)
        -- 开启释放计时器, 一段时间状态未切换则释放房间
        frameCenter.timerMgr:updateTimer(batId, gPvpTimerType.status, svrFunc.systemTime()+gPvpFreeTime)
    end
    return self.rooms[batId]
end

-- 释放room
function userMgr:delRoom(batId)
    gLog.i("userMgr:delRoom=", batId, self.rooms[batId])
    local room = self.rooms[batId]
    if room then
        -- 删除倒计时
        for k,v in pairs(gPvpTimerType) do
            frameCenter.timerMgr:updateTimer(batId, v, 0)
        end
        -- 释放user
        local addr = svrAddrMgr.getSvr(svrAddrMgr.gatepvpSvr, frameCenter.kid)
        local users = room:getUsers()
        for uid,_ in pairs(users) do
            local user = self:getUser(uid, true)
            if user then
                skynet.send(addr, "lua", "afk", uid, user:getSubid(), 1)
            end
        end
        -- 释放room
        self.rooms[batId] = nil
        room = nil
    end
    --gLog.dump(self, "userMgr:delRoom batId="..tostring(batId))
end

-- 根据fd获取user
function userMgr:getFdMap(fd)
    if fd then
        return self.fdMap[fd]
    end
end

-- 维护玩家fd关联
function userMgr:setFdMap(fd, user)
    if fd then
        if user then
            self.fdMap[fd] = user
        else
            self.fdMap[fd] = nil
        end
    end
end

-- 协程跑逻辑帧
function userMgr:game(tick, batId, room)
    gLog.d("userMgr:game=", batId, room)
    if self.co then
        self.gaming[batId] = room
        return
    end
    self.gaming[batId] = room
    self.co = skynet.fork(function()
        local ti = nil
        while(true) do
            ti = lextra.c_time()
            for k,v in pairs(self.gaming) do
                if v:game() then
                    self.gaming[k] = nil
                end
            end
            if frameCenter.stoped then
                break
            else
                ti = lextra.c_time() - ti -- 单位=1ms
                ti = math.floor(ti/10) --单位=10ms=1/100s
                skynet.sleep(tick - ti)
            end
        end
    end)
end

return userMgr
