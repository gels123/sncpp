--[[
	设置信息模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local baseCtrl = require("baseCtrl")
local settingCtrl = class("settingCtrl", baseCtrl)

-- 构造
function settingCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "setting" -- 数据表名
end

-- 初始化
function settingCtrl:init()
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
end

-- 默认数据
function settingCtrl:defaultData(uid, kid)
    return {
        --push = {}, -- 推送设置
    }
end

-- 获取初始化数据
function settingCtrl:getInitData()
    return self.data
end

-- 获取存库数据
function settingCtrl:getDataDB()
    return self.data
end

return settingCtrl
