--[[
	rpg模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local mapLib = require("mapLib")
local baseCtrl = require("baseCtrl")
local rpgCtrl = class("rpgCtrl", baseCtrl)

-- 构造
function rpgCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "rpginfo" -- 数据表名
    self.tp = nil           -- 地图类型
    self.mapid = nil        -- 地图id
end

-- 初始化
function rpgCtrl:init()
    if self.bInit then
        return
    end
    -- 设置已初始化
    self.bInit = true
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData()
        self:updateDB()
    end
    --gLog.dump(self.data, "rpgCtrl:init self.data=")
end

-- 默认数据
function rpgCtrl:defaultData()
    return {
        v = 1,              -- 版本
    }
end

-- 获取buff初始化数据
function rpgCtrl:getInitData()
    return self.data
end

function rpgCtrl:checkin()

end

function rpgCtrl:afk()
    self:exitMap()
end

function rpgCtrl:logout()
    self:exitMap()
end

-- 进入地图
function rpgCtrl:enterMap(tp, move)
    --
    if self.tp and self.mapid then
        return false, gErrDef.Err_ENTER_MAP
    end
    -- 查找未满员的地图, 无则创建
    local mapid = mapLib:call(player:getKid(), player:getUid(), "findMap", tp)
    if not mapid then
        mapid = require("snowflake").nextid()
    end
    --
    local ok = mapLib:call(player:getKid(), mapid, "enterMap", player:getUid(), tp, mapid, move)
    if not ok then
        return false
    end
    self.tp = tp
    self.mapid = mapid
    --self:updateDB()
    return true, mapid
end

-- 退出地图
function rpgCtrl:exitMap()
    if self.tp and self.mapid then
        mapLib:send(player:getKid(), self.mapid, "exitMap", player:getUid(), self.tp, self.mapid)
        self.tp = nil
        self.mapid = nil
        --self:updateDB()
    end
end

-- 移动
function rpgCtrl:move(move)
    if self.tp and self.mapid then
        return mapLib:call(player:getKid(), self.mapid, "move", player:getUid(), self.tp, self.mapid, move)
    end
end

return rpgCtrl
