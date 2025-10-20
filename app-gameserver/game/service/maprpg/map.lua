--[[
	地图
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local redisLib = require "redisLib"
local agentLib = require "agentLib"
local mapCenter = require("mapCenter"):shareInstance()
local map = class("map")

-- 构造
function map:ctor(tp, mapid)
    -- 地图类型
    self.tp = tp
    -- 地图ID
    self.mapid = mapid
    -- 地图对象类型-对象类
    self.objType2Class =
    {
        --[mapConf.objTypes.monster] = require("mapObjectMonster"),
    }
	-- 地图对象
	self.objs = {}
    -- 地图对象管理
    self.objMgrs =
    {
        --[mapConf.objTypes.monster] = require("mapObjectMonster"),
    }
    -- 玩家
    self.users = {}
    self.uids = {}
end

-- 初始化
function map:init()
    gLog.i("==map:init begin==")
	-- 加载db数据
	self:loadDb()
    gLog.i("==map:init end==")
end

-- 加载db数据
function map:loadDb()

end

-- 进入地图
function map:enterMap(uid, move)
    if not self.users[uid] then
        self.users[uid] = {}
        table.insert(self.uids, uid)
    end
    self.users[uid].uid = uid
    self.users[uid].move = move
    -- 推送客户端
    if #self.uids >= 2 then
        agentLib:notifyMsgBatch(mapCenter.kid, self.uids, "notifyRpgMove", {mv = {self.users[uid]},}, uid)
    end
    -- 更新地图同屏人数排序
    if #self.uids >= mapConf.mapAoiMax then
        redisLib:sendzRem(mapCenter.mapMgr:findMapKey(self.tp), tostring(self.mapid))
    else
        redisLib:sendzAdd(mapCenter.mapMgr:findMapKey(self.tp), #self.uids, tostring(self.mapid))
    end
    return true
end

-- 离开地图
function map:exitMap(uid)
    if self.users[uid] then
        self.users[uid] = nil
        for k,v in ipairs(self.uids) do
            if v == uid then
                table.remove(self.uids, k)
                break
            end
        end
        -- 推送客户端
        if #self.uids >= 1 then
            agentLib:notifyMsgBatch(mapCenter.kid, self.uids, "notifyRpgMove", {mv = {{uid = uid,}}}, uid)
        end
        -- 更新地图同屏人数排序
        if #self.uids < mapConf.mapAoiMax then
            redisLib:sendzAdd(mapCenter.mapMgr:findMapKey(self.tp), #self.uids, tostring(self.mapid))
        end
        return true
    end
end

-- 移动
function map:move(uid, move)
    if self.users[uid] then
        self.users[uid].move = move
        -- 推送客户端
        if #self.uids >= 2 then
            agentLib:notifyMsgBatch(mapCenter.kid, self.uids, "notifyRpgMove", {mv = {self.users[uid]},}, uid)
        end
        return true
    end
end

return map