-- 服务器配置
local dbconf = {}

-- 数据库类型(mysql/mongodb)
dbconf.dbtype = "mongodb"

-- 游戏配置库配置
dbconf.mysql_confdb =
{
    host = "127.0.0.1",
    port = 3306,
    database = "game_conf",
    user = "root",
    password = "root123",
    max_packet_size = 1024 * 1024,
    instance = 2,
}

-- 游戏数据库配置
dbconf.mysql_gamedb =
{
    host = "127.0.0.1",
    port = 3306,
    database = "game_data",
    user = "root",
    password = "root123",
    max_packet_size = 1024 * 1024,
    instance = 8,
}

-- 游戏配置库配置
dbconf.mongodb_confdb =
{
    host = "127.0.0.1",
    port = 27017,
    database = "game_conf",
    username = "root",
    password = "root",
	authdb = "admin",
    instance = 2,
}

-- 游戏数据库配置
dbconf.mongodb_gamedb =
{
    host = "127.0.0.1",
    port = 27017,
    database = "game_data",
    username = "root",
    password = "root",
	authdb = "admin",
    instance = 8,
}

-- 本地redis配置
dbconf.redis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    auth="1",
    instance = 8,
    --name = "mymaster",
    --sentinels = {
    --    {
    --        host="10.8.10.87",
    --        port=28001,
    --        db=1,
    --        --auth="1",
    --    },
    --    {
    --        host="10.8.10.87",
    --        port=28002,
    --        db=1,
    --        --auth="1",
    --    },
    --    {
    --        host="10.8.10.87",
    --        port=28003,
    --        db=1,
    --        --auth="1",
    --    }
    --},
}

-- 共享redis配置
dbconf.publicRedis =
{
    host="127.0.0.1",
    port=6379,
    db=0,
    auth="1",
    instance = 8,
}

-- 运营日志打点相关配置
dbconf.log4GmOn = true
dbconf.log4GmUrl = "https://receiver.ta.thinkingdata.cn"
dbconf.log4GmAppID = "xxxx"
dbconf.log4GmBatchNumber = 50
dbconf.log4GmCacheCapacity = 500
dbconf.log4FilePath = "/home/slgzgmlog"
dbconf.log4ZtFilePath = "/home/slgzgmlog"
dbconf.log4ZtUrl = "xxxx"
dbconf.log4ZtAppID = "demo.global.development"
dbconf.log4ZtAppKey = "xxxx"

-- 钉钉/微信报错信息通知url
dbconf.robotTag = "gels-game"
--dbconf.robotUrl = "https://oapi.dingtalk.com/robot/send?access_token=9848749207a29936a54e559b77be02c9293f5c04e90c6601776fc87b6bd39663"

-- 密钥
dbconf.secret = "<&Gate*($le_@!NBf>"

-- 是否开启存库检查
dbconf.SAVE_DB_CHECK = true

-- 是否开启调试
dbconf.DEBUG = true

-- 是否开启后台
dbconf.BACK_DOOR = true

-- 游戏节点id
dbconf.gamenodeid = 1

-- 测试服dbconf重定向
if dbconf.DEBUG then
    local lfs = require("lfs")
    if tostring(...) == "dbconf" and lfs.exist(lfs.currentdir().."/dbconflocal.lua") then
        --print("dbconf.lua redict to dbconflocal.lua")
        return require("dbconflocal")
    end
end

return dbconf
