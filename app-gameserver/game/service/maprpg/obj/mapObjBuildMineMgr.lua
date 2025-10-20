--[[
-- 地图建筑矿、碉堡管理
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local Random = require "random"
local mapCenter = require("mapCenter"):shareInstance()
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjBuildMineMgr = class("mapObjBuildMineMgr", mapRefreshMgr)

return mapObjBuildMineMgr
