--[[
    大地图生成器
]]
local skynet = require ("skynet")
local cluster = require ("cluster")
local md5 = require ("md5")
local json = require "json"
local socket = require "skynet.socket"

xpcall(function()
    gLog.i("=====genMap begin")
    print("=====genMap begin")

    local mapSize, chunkSize, bigChunkSize = 1197, 9, 19  --地图尺寸、地图块尺寸、地图大块尺寸
    local size, n = (mapSize/chunkSize), math.floor((mapSize/chunkSize)/bigChunkSize)
    local array = {}
    for y = 1, size, 1 do
        array[y] = {}
        for x = 1, size, 1 do
            local c = 65 + math.floor((y-1)/bigChunkSize) * n + math.floor((x-1)/bigChunkSize)
            if c >= 92 then
                c = c + 1
            end
            table.insert(array[y], "'" ..string.char(c).."'")
        end
    end

    local str = "local map = { --test map size 133 * 133\n"
    for k,v in ipairs(array) do
        str = string.format("%s{%s},\n", str, table.concat(v, ","))
    end
    str = string.format("%s}\nreturn map;\n", str)
    io.writefile("server/map/search/testmap/map3.lua", str, "w+")

    gLog.i("=====genMap end")
    print("=====genMap end")
end, serviceFunctions.exception)

