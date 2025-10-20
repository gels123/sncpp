--[[
    道具配置管理
]]
local skynet = require "skynet"
local sharedataLib = require "sharedataLib"
local itemCfgMgr = class("itemCfgMgr")

function itemCfgMgr:init()
    self.itemCfg = sharedataLib.itemCfg
end

function itemCfgMgr:getItemCfg()
    return self.itemCfg
end

return itemCfgMgr