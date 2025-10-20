--[[
    main函数
]]
local skynet = require("skynet")
local cluster = require("cluster")
local dbconf = require("dbconf")
local svrConf = require("svrConf")
local initDBConf = require("initDBConf")
local svrAddrMgr = require("svrAddrMgr")
local sharedataLib = require("sharedataLib")

skynet.start(function ()
    local ok = xpcall(function()
        print("====== main start begin =======")
        gLog.i("====== main start begin =======")
        -- 设置统一的随机种子
        math.randomseed(os.time())
        gLog.i("====== main start 0 =======")

        -- 报错信息通知服务
        skynet.newservice("alertService")
        gLog.i("====== main start 1 =======")

        -- 检查节点配置
        assert(dbconf.gamenodeid and not dbconf.globalnodeid)
        skynet.setenv("nodeid", dbconf.gamenodeid)
        gLog.i("====== main start 2 =======")

        -- 配置数据DB服务
        if dbconf.dbtype == "mysql" then
            local address = skynet.newservice("mysqlService", "master", dbconf.mysql_confdb.instance)
            svrAddrMgr.setSvr(address, svrAddrMgr.confDBSvr)
            skynet.call(address, "lua", "connect", dbconf.mysql_confdb)
        elseif dbconf.dbtype == "mongodb" then
            local address = skynet.newservice("mongodbService", "master", dbconf.mongodb_confdb.instance)
            svrAddrMgr.setSvr(address, svrAddrMgr.confDBSvr)
            skynet.call(address, "lua", "connect", dbconf.mongodb_confdb)
        else
            assert(false, "dbconf.dbtype error"..tostring(dbconf.dbtype))
        end
        gLog.i("====== main start 3 =======")

        -- 游戏数据DB服务
        if dbconf.dbtype == "mysql" then
            local address = skynet.newservice("mysqlService", "master", dbconf.mysql_gamedb.instance)
            svrAddrMgr.setSvr(address, svrAddrMgr.gameDBSvr)
            skynet.call(address, "lua", "connect", dbconf.mysql_gamedb)
        elseif dbconf.dbtype == "mongodb" then
            local address = skynet.newservice("mongodbService", "master", dbconf.mongodb_gamedb.instance)
            svrAddrMgr.setSvr(address, svrAddrMgr.gameDBSvr)
            skynet.call(address, "lua", "connect", dbconf.mongodb_gamedb)
        else
            assert(false, "dbconf.dbtype error"..tostring(dbconf.dbtype))
        end
        gLog.i("====== main start 4 =======")

        -- 本地redis服务
        local address = skynet.newservice("redisService", "master", dbconf.redis.instance, "master")
        svrAddrMgr.setSvr(address, svrAddrMgr.redisSvr)
        skynet.call(address, "lua", "connect", dbconf.redis)
        gLog.i("====== main start 5 =======")

        -- 公共redis服务
        local address = skynet.newservice("redisService", "master", dbconf.publicRedis.instance, "master")
        svrAddrMgr.setSvr(address, svrAddrMgr.publicRedisSvr)
        skynet.call(address, "lua", "connect", dbconf.publicRedis)
        gLog.i("====== main start 6 =======")

        -- 加载服务器配置、刷库
        initDBConf:set()
        initDBConf:executeGameDataSql()
        gLog.i("====== main start 7 =======")

        -- 调试控制台服务
        skynet.newservice("debug_console", svrConf:debugConfGame(dbconf.gamenodeid).port)
        gLog.i("====== main start 8 =======debugport=", svrConf:debugConfGame(dbconf.gamenodeid).port)

        -- 集群配置
        cluster.open(svrConf:clusterConfGame(dbconf.gamenodeid).listennodename)
        gLog.i("====== main start 9 =======")

        --本地数据共享服务
        skynet.newservice("localData")
        gLog.i("====== main start 10 =======")

        -- 协议共享服务
        skynet.newservice("protoService")
        gLog.i("====== main start 11 =======")

        -- 网关服务
        skynet.newservice("gateService")
        gLog.i("====== main start 12 =======")

        -- es搜索服务
        skynet.newservice("elasticSearchService", 1, "elastic", "elastic")
        gLog.i("====== main start 13 =======")

        -- 事件服务
        skynet.uniqueservice("eventService", dbconf.gamenodeid)
        gLog.i("====== main start 14 =======")

        -- 启动王国相关服务
        local kidList = svrConf:getKingdomIDListByNodeID(dbconf.gamenodeid)
        for _,kid in ipairs(kidList) do
            -- 服务启动服务
            skynet.newservice("serverStartService", kid)
            gLog.i("====== main start 15 =======", kid)

            -- 数据中心服务
            local playerDataLib = require("playerDataLib")
            for i = 1, playerDataLib.serviceNum do
                skynet.newservice("playerDataService", kid, i)
            end
            gLog.i("====== main start 16 =======", kid)

            -- 是否开启调时间fakeTime(s)
            if dbconf.DEBUG and dbconf.BACK_DOOR then
                local r = io.popen("find ./skynet/3rd/jemalloc/ -name *.a"):read("*all")
                if not (r and string.find(r, ".a")) then
                    skynet.call(svrAddrMgr.getSvr(svrAddrMgr.startSvr, kid), "lua", "addFakeTime", 0)
                end
            end
            gLog.i("====== main start 17 =======", kid)

            -- 玩家代理池服务
            skynet.newservice("agentPoolService", kid)
            gLog.i("====== main start 18 =======", kid)

            -- 运营日志打点服务
            skynet.newservice("logService", kid)
            gLog.i("====== main start 19 =======", kid)

            -- 缓存服务
            skynet.newservice("cacheService", kid)
            gLog.i("====== main start 20 =======", kid)

            -- 邮件服务
            for i = 1, require("mailLib").serviceNum do
                skynet.newservice("mailService", kid, i)
            end
            gLog.i("====== main start 21 =======", kid)

            -- 排行榜服务
            for i = 1, require("rankLib").serviceNum do
                skynet.newservice("rankService", kid, i)
            end
            gLog.i("====== main start 22 =======", kid)

            -- pvp网关服务 1=rudp nil=tcp
            local rudp = nil
            --skynet.newservice("gatepvp", kid, rudp)
            gLog.i("====== main start 23 =======", kid)

            -- 帧同步服务
            --for i = 1, require("frameLib").serviceNum do
            --    skynet.newservice("frameService", kid, i, rudp)
            --end
            gLog.i("====== main start 23 =======", kid)

            -- 寻路服务
            --for i = 1, require("searchLib").serviceNum do
            --    skynet.newservice("searchService", kid, i)
            --end
            --gLog.i("====== main start 24 =======", kid)

            -- aoi视野服务
            --skynet.newservice("aoiService", kid)

            -- 地图服务
            --for i = 1, require("mapLib").serviceNum do
            --    skynet.newservice("mapService", kid, i)
            --end

            -- 行军队列服务
            --skynet.newservice("queueService", kid)
            gLog.i("====== main start 25 =======", kid)
        end

        -- 登录服刷新配置
        local loginConf = initDBConf:getLoginConf()
        for k,v in pairs(loginConf) do
           pcall(function()
               local r = string.trim(io.popen(string.format("echo ' ' | telnet %s %d", v.web ~= "127.0.0.1" and v.web ~= "localhost" and v.web or v.host, v.port)):read("*all") or "")
               if string.find(r, "Connected") then
                   local startSvr = svrConf:getSvrProxyLogin(v.nodeid, svrAddrMgr.startSvrG)
                   skynet.send(startSvr, "lua", "reloadConf", dbconf.gamenodeid)
               end
           end)
        end
        -- 全局服刷新配置
        local globalConf = initDBConf:getGlobalConf()
        for k,v in pairs(globalConf) do
           pcall(function()
               local r = string.trim(io.popen(string.format("echo ' ' | telnet %s %d", v.web ~= "127.0.0.1" and v.web ~= "localhost" and v.web or v.ip, v.port)):read("*all") or "")
               if string.find(r, "Connected") then
                   local startSvr = svrConf:getSvrProxyGlobal(v.nodeid, svrAddrMgr.startSvrG)
                   skynet.send(startSvr, "lua", "reloadConf", dbconf.gamenodeid)
               end
           end)
        end
        -- 游戏服刷新配置
        local kingdomConf = initDBConf:getKingdomConf()
        for k,v in pairs(kingdomConf) do
           if v.nodeid ~= dbconf.gamenodeid then
               pcall(function()
                   local r = string.trim(io.popen(string.format("echo ' ' | telnet %s %d", v.web ~= "127.0.0.1" and v.web ~= "localhost" and v.web or v.ip, v.port)):read("*all") or "")
                   if string.find(r, "Connected") then
                       local startSvr = svrConf:getSvrProxyGame2(v.nodeid, svrAddrMgr.getSvrName(svrAddrMgr.startSvr, v.kid))
                       skynet.send(startSvr, "lua", "reloadConf", dbconf.gamenodeid)
                   end
               end)
           end
        end
        gLog.i("====== main start 25 =======")

        -- 游戏服网关OPEN后向登录服发送心跳
        local gateSvr = svrAddrMgr.getSvr(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
        skynet.call(gateSvr, "lua", "heartbeat2LoginSvr")
        gLog.i("====== main start 26 =======")

        -- 标记启动成功并生成文件
        if require("serverStartLib"):getIsOk(kidList[1]) then
            gLog.i("====== main start success ======= testjson=", require("json").encode({[1] = {num = 1}, [5] = {num = 2}}))
            local file = io.open('./.startsuccess_game', "w+")
            file:close()
            -- 退出
            skynet.exit()
        else
            -- 启动失败, 等待日志输出5s后杀进程
            gLog.i("====== main start failed =======")
            skynet.timeout(500, function()
                require("lextra").reset_singal_handler()
            end)
        end
    end, svrFunc.exception)

    -- 启动失败, 等待日志输出5s后杀进程
    if not ok then
        gLog.i("====== main start failed =======")
        -- skynet.timeout(500, function()
        --     require("lextra").reset_singal_handler()
        -- end)
    end
end)