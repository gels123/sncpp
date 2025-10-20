--[[
    大地图生成器
    inject 00000038 server/map/search/bitmap/genMapRelease.lua
]]
local skynet = require ("skynet")
local cluster = require ("cluster")
local md5 = require ("md5")
local json = require "json"
local mapUtils = require "mapUtils"
local socket = require "skynet.socket"

xpcall(function()
    gLog.i("=====genMapRelease begin")
    print("=====genMapRelease begin")

    local MapMask = require("bitmap.EditMapMask") --平地0、高地1、铁轨2、高地上面的低地/水3、档格4(毒泉/山脉)
    local tmp = {}
    for k,v in pairs(MapMask) do
        if v.x and v.y and v.subzone and v.terrain then
            if not tmp[v.y] then
                tmp[v.y] = {}
            end
            if v.subzone == 0 or (v.terrain == 4 and v.subzone == 0) then
                tmp[v.y][v.x] = "500" --行军档格
            else
                if v.subzone == 999 then
                    tmp[v.y][v.x] = "000" --行军关卡
                else
                    tmp[v.y][v.x] = tostring(v.subzone)
                end
            end
            --debug
            --if mapUtils.get_chunck_id(v.x, v.y) == mapUtils.get_chunck_id(310, 826) then
            --    gLog.d("==========xx====", v.x, v.y, tmp[v.y][v.x])
            --end
        else
            gLog.e("genMapRelease error")
        end
    end

    local str = "posmap = { --chunck map size 1197 * 1197\n"
    for k,v in ipairs(tmp) do
        str = string.format("%s{%s},\n", str, table.concat(v, ","))
    end
    str = string.format("%s};\n", str)
    str = string.format("%sfunction get(x, y)\n\treturn posmap[y] and posmap[y][x] or 0\nend\n return posmap;\n", str)
    io.writefile("server/map/search/bitmap/posmap.lua", str, "w+")

    local mapSize, chunkSize, bigChunkSize = 1197, 9, 19  --地图尺寸、地图块尺寸、地图大块尺寸
    local size = (mapSize/chunkSize)
    local array = {}
    for y = 1, size, 1 do
        array[y] = {}
        for x = 1, size, 1 do
            local subzone = nil
            local chunckid = mapUtils.get_chunck_id2(x, y)
            local px, py = mapUtils.chunck_id_to_pos(chunckid)
            if mapUtils.get_chunck_id(px, py) ~= chunckid then
                gLog.e("genMapRelease error", x, y, chunckid, px, py)
            end
            for i=0,chunkSize-1,1 do
                for j=0,chunkSize-1,1 do
                    local t = tonumber(tmp[py+i][px+j])
                    if not subzone then
                        subzone = t
                    end
                    if subzone ~= 0 and subzone ~= t then
                        if t == 0 then
                            subzone = t
                        elseif t > subzone then
                            subzone = t
                        end
                    end
                    --if x==27 and y==96 then print("xxxxx=====subzone=", subzone, px+i, py+j, t) end
                end
            end
            --if x==27 and y==96 then print("xxxxx=====subzonexxx=", subzone) end
            table.insert(array[y], string.format("%03d", subzone))
        end
    end
    for y = 1, size, 1 do
        for x = 1, size, 1 do
            if array[y][x] == "000" then
                if (array[y][x-1] ~= "500" and array[y][x+1] ~= "500") or (array[y-1][x] ~= "500" and array[y+1][x] ~= "500") then
                else
                    if array[y][x-1] ~= "500" then
                        array[y][x+1] = array[y][x+2]
                    end
                    if array[y][x+1] ~= "500" then
                        array[y][x-1] = array[y][x-2]
                    end
                    if array[y-1][x] ~= "500" then
                        array[y+1][x] = array[y+2][x]
                    end
                    if array[y+1][x] then
                        array[y-1][x] = array[y-2][x]
                    end
                end
            end
        end
    end

    local str = "chunckmap = { --chunck map size 133 * 133\n"
    for k,v in ipairs(array) do
        str = string.format("%s{%s},\n", str, table.concat(v, ","))
    end
    str = string.format("%s};\n", str)
    str = string.format("%sfunction get(x, y)\n\treturn chunckmap[y] and chunckmap[y][x] or 0\nend\n return chunckmap;\n", str)
    io.writefile("server/map/search/bitmap/chunckmap.lua", str, "w+")


    local area = get_static_config().area
    local zoneconnect, zoneconnectcheck  = {}, {}
    for y = 1, mapSize, 1 do
        for x = 1, mapSize, 1 do
            if tmp[y][x] == "000" then
                local zone1, x1, y1, zone2, x2, y2 = nil, nil, nil, nil, nil, nil
                for yy=y,y+9,1 do
                    if tmp[yy][x] == "500" then
                        zone1 = nil
                        x1 = nil
                        y1 = nil
                        break
                    end
                    if tonumber(tmp[yy][x]) > 0 and not zone1 then
                        zone1 = tonumber(tmp[yy][x])
                        x1 = x
                        y1 = yy
                    end
                end
                for yy=y,y-9,-1 do
                    if tmp[yy][x] == "500" then
                        zone2 = nil
                        x2 = nil
                        y2 = nil
                        break
                    end
                    if tonumber(tmp[yy][x]) > 0 and not zone2 then
                        zone2 = tonumber(tmp[yy][x])
                        x2 = x
                        y2 = yy
                    end
                end
                if zone1 and zone2 and zone1 ~= zone2 then
                    if zone1 > zone2 then
                        zone1, x1, y1, zone2, x2, y2 = zone2, x2, y2, zone1, x1, y1
                    end
                    local key = string.format("%d_%d_%d_%d_%d_%d", zone1, x1, y1, zone2, x2, y2)
                    if not zoneconnectcheck[key] then
                        zoneconnectcheck[key] = true
                        local cx1, cy1 = mapUtils.chunckxy(x1, y1)
                        local cx2, cy2 = mapUtils.chunckxy(x2, y2)
                        local cid1 = mapUtils.get_chunck_id2(cx1, cy1)
                        local centerid1 = mapUtils.chunck_id_center_id(cid1)
                        local centerid2 = mapUtils.chunck_id_center_id(mapUtils.get_chunck_id2(cx2, cy2))
                        if centerid1 ~= centerid2 then
                            gLog.e("genMapRelease zoneconnect error", centerid1, centerid2)
                        end
                        if area[cid1] and (area[cid1].TerrBuild.Type == mapcommon.object_type.checkpoint or area[cid1].TerrBuild.Type == mapcommon.object_type.wharf) then
                        else
                            gLog.w("genMapRelease zoneconnect zone1=", zone1, "zone2=", zone2, centerid1, centerid2)
                            centerid1 = 0
                        end
                        table.insert(zoneconnect, {zone1 = zone1, x1 = x1, y1 = y1, zone2 = zone2, x2 = x2, y2 = y2, centerid = centerid1})
                    end
                else
                    local zone1, x1, y1, zone2, x2, y2 = nil, nil, nil, nil, nil, nil
                    for xx=x,x+9,1 do
                        if tmp[y][xx] == "500" then
                            zone1 = nil
                            x1 = nil
                            y1 = nil
                            break
                        end
                        if tonumber(tmp[y][xx]) > 0 and not zone1 then
                            zone1 = tonumber(tmp[y][xx])
                            x1 = xx
                            y1 = y
                        end
                    end
                    for xx=x,x-9,-1 do
                        if tmp[y][xx] == "500" then
                            zone2 = nil
                            x2 = nil
                            y2 = nil
                            break
                        end
                        if tonumber(tmp[y][xx]) > 0 and not zone2 then
                            zone2 = tonumber(tmp[y][xx])
                            x2 = xx
                            y2 = y
                        end
                    end
                    if zone1 and zone2 and zone1 ~= zone2 then
                        if zone1 > zone2 then
                            zone1, x1, y1, zone2, x2, y2 = zone2, x2, y2, zone1, x1, y1
                        end
                        local key = string.format("%d_%d_%d_%d_%d_%d", zone1, x1, y1, zone2, x2, y2)
                        if not zoneconnectcheck[key] then
                            zoneconnectcheck[key] = true
                            local cx1, cy1 = mapUtils.chunckxy(x1, y1)
                            local cx2, cy2 = mapUtils.chunckxy(x2, y2)
                            local cid1 = mapUtils.get_chunck_id2(cx1, cy1)
                            local centerid1 = mapUtils.chunck_id_center_id(cid1)
                            local centerid2 = mapUtils.chunck_id_center_id(mapUtils.get_chunck_id2(cx2, cy2))
                            if centerid1 ~= centerid2 then
                                gLog.e("genMapRelease zoneconnect error", centerid1, centerid2)
                            end
                            if area[cid1] and (area[cid1].TerrBuild.Type == mapcommon.object_type.checkpoint or area[cid1].TerrBuild.Type == mapcommon.object_type.wharf) then
                            else
                                gLog.w("genMapRelease zoneconnect zone1=", zone1, "zone2=", zone2, centerid1, centerid2)
                                centerid1 = 0
                            end
                            table.insert(zoneconnect, {zone1 = zone1, x1 = x1, y1 = y1, zone2 = zone2, x2 = x2, y2 = y2, centerid = centerid1})
                        end
                    else
                        gLog.e("genMapRelease error zoneconnect", x, y, zone1, zone2)
                    end
                end
            end
        end
    end
    --补充站点间联通的关卡信息
    local EditMapRailwayServer = require("bitmap.EditMapRailwayServer")
    for k,v in ipairs(zoneconnect) do
        if v.centerid > 0 then
            local find = false
            for kk,vv in pairs(EditMapRailwayServer) do
                for _,id in ipairs(vv.path) do
                    if id == v.centerid then
                        find = true
                        v.railway1 = vv.id1
                        v.railway2 = vv.id2
                        break
                    end
                end
                if find then
                    break
                end
            end
        end
    end
    local str = "zoneconnect = {\n"
    for k,v in ipairs(zoneconnect) do
        str = string.format("%s{zone1 = %d, x1 = %d, y1 = %d, zone2 = %d, x2 = %d, y2 = %d, railway1 = %d, railway2 = %d, centerid = %d},\n", str, v.zone1, v.x1, v.y1, v.zone2, v.x2, v.y2, v.railway1 or 0, v.railway2 or 0, v.centerid)
    end
    str = string.format("%s};\n", str)
    str = string.format("%s\nlocal idx = 0\nfunction getZoneConnect()\n\tidx = idx + 1\n\tif zoneconnect[idx] then\n\t\treturn zoneconnect[idx].zone1, zoneconnect[idx].x1, zoneconnect[idx].y1, zoneconnect[idx].zone2, zoneconnect[idx].x2, zoneconnect[idx].y2, zoneconnect[idx].railway1, zoneconnect[idx].railway2, zoneconnect[idx].centerid\n\telse\n\t\treturn 0, 0, 0, 0, 0, 0, 0, 0, 0\n\tend\nend\n", str)
    str = string.format("%s\nreturn zoneconnect\n", str)
    io.writefile("server/map/search/bitmap/zoneconnect.lua", str, "w+")

    gLog.i("=====genMapRelease end")
    print("=====genMapRelease end")
end, serviceFunctions.exception)

