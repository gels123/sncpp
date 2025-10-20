--[[
	地图相关常量
]]

--地图类型定义
gMapType = {
    map1 = 1,
}

--地图aoi配置
gMapAoi = {
    [gMapType.map1] = {
        mapId = gMapType.map1,
        width = 1000,
        height = 1000,
        aois = {
            [1] = {
                lv = 1,
                cell = 10,
                range = 1,
            }
        },
    }
}
