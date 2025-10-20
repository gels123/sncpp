--[[
	地图模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local baseCtrl = require("baseCtrl")
local mapCtrl = class("mapCtrl", baseCtrl)

-- 构造
function mapCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "mapinfo" -- 数据表名
end

-- 初始化
function mapCtrl:init()
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
    --gLog.dump(self.data, "mapCtrl:init self.data=")
end

-- 默认数据
function mapCtrl:defaultData()
    return {
        v = 1,             -- 版本
    }
end

-- 获取buff初始化数据
function mapCtrl:getInitData()
    return self.data.effects or {}
end

return mapCtrl
