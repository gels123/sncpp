--[[
    rpg地图配置
]]
local mapConf = class("mapConf")

--地图类型定义
mapConf.mapTypes = {
    map = 1,   -- 通用地图
}

--地图对象类型定义
mapConf.objTypes = {
    monster = 1,   -- 怪物
}

--地图计时器定义
mapConf.mapTimers = {
    delmap = "delmap", -- 删除地图
}

--地图对象计时器定义
mapConf.objTimers = {
    delobj = "delobj", -- 删除对象
}

--地图同屏人数上限
mapConf.mapAoiMax = 10

return mapConf
