--[[
    k8s重启IP会变化, 新增/修正/刷新节点配置, 启动前执行本脚本: ./skynet/3rd/lua/lua ./fixconf.lua 'dbconflocal.lua'`
]]
package.cpath =
        "skynet/luaclib/?.so;" ..
        "skynet/cservice/?.so;" ..
        "game/lib/lua-timer/?.so;" ..
        "game/lib/lua-socket/src/?.so;" ..
        "game/lib/lua-lfs/?.so;" ..
        "game/lib/lua-bit32/?.so;" ..
        "game/lib/lua-json/?.so;" ..
        "game/lib/luasql/src/?.so;"

package.path =
        "?.lua;" ..
        "skynet/lualib/?.lua;" ..
        "skynet/lualib/compat10/?.lua;" ..
        "game/lib/?.lua;" ..
        "game/lib/lua-timer/?.lua;" ..
        "game/lib/lua-socket/?.lua;" ..
        "game/lib/lua-json/?.lua;" ..
        "game/service/proto/?.lua;" ..
        "game/service/simulate/?.lua;"

require "quickframework.init"

local filename = ...
filename = tostring(filename or "")
local dbconf = require(string.sub(filename,1,string.find(filename,".lua")-1))

-- 自动校验并修正配置
local function checkAndFixConf(filename)
    if not dbconf.PROD then
        print("checkAndFixConf ignore: not prod env.")
        return true
    end
    local conf = dbconf.mysql_confdb
    assert(conf, "mysqlService connect error: no conf!")

    local luasql = require "lmysql"
    local env = luasql.mysql()
    local conn = env:connect(conf.database, conf.user, conf.password, conf.host, conf.port)
    if not conn then
        print("checkAndFixConf error1: conn invalid.")
        return false
    end
    conn:execute("set names utf8mb4")

    local function query(sql)
        local ret = {}
        local cur = conn:execute(sql)
        local row = cur:fetch({},"a")
        while row do
            table.insert(ret, row)
            row = cur:fetch(row,"a")
        end
        return ret
    end

    -- 节点key
    local nodekey = "game1"
    -- 公网ip、专网ip
    local outIp, inIp = "127.0.0.1", "127.0.0.1"
    local outIp_ = string.trim(io.popen("curl --connect-timeout 2 -m 2 http://169.254.169.254/latest/meta-data/public-ipv4"):read("*all") or "")
    if string.len(outIp_) > 0 and not string.find(outIp_, "curl") then
        outIp = outIp_
    end
    local inIp_ = string.trim(io.popen("echo $IP"):read("*all") or "")
    if string.len(inIp_) > 0 then
        inIp = inIp_
    end
    -- conf_cluster配置
    local sql = string.format("SELECT * FROM `conf_cluster` WHERE `nodekey` = '%s'", nodekey)
    local ret = query(sql)
    print("checkAndFixConf do1 nodekey=", nodekey, "outIp=", outIp, "inIp=", inIp, "conf_cluster ret=", table2string(ret))
    -- 更新/插入dbconf.gamenodeid文件
    local nodeid = nil
    if ret and ret[1] and ret[1].nodeid then
        -- 修改dbconf.gamenodeid文件
        nodeid = ret[1].nodeid
        local cmd1 = string.format("grep \"dbconf.gamenodeid\" %s", filename)
        local ret1 = string.trim(io.popen(cmd1):read("*all") or "")
        if string.len(ret1) <= 0 then
            print("checkAndFixConf error2: cmd1 invalid.", cmd1)
            return false
        end
        local cmd2 = string.format("sed -i 's/%s/dbconf.gamenodeid = %d/g' %s", ret1, nodeid, filename)
        local ret2 = string.trim(io.popen(cmd2):read("*all") or "")
        print("checkAndFixConf do2 nodekey=", nodekey, "filename=", filename, "old gamenodeid=", cmd1, ret1, "new gamenodeid=", cmd2, ret2, string.trim(io.popen(cmd1):read("*all") or ""))
        -- 更新conf_cluster
        local sql = string.format([[UPDATE `conf_cluster` SET `nodename` = '%s', `ip` = '%s', `web` = '%s', `listennodename` = '%s', `port` = '%d', `type` = '%d'
        WHERE `nodeid` = '%d';]], string.format("nodegame_%d", nodeid), inIp, inIp, string.format("listen_nodegame_%d", nodeid), 20001, 3, nodeid)
        local ret3 = conn:execute(sql)
        print("checkAndFixConf do3 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "update conf_cluster ret=", ret3)
        if not (tonumber(ret3) == 1 or tonumber(ret3) == 0) then
            print("checkAndFixConf error3: update conf_cluster.", ret3)
            return false
        end
    else
        -- 生成新的nodeid
        local sql = string.format("SELECT max(`nodeid`) maxnodeid FROM `conf_cluster` WHERE `nodename` like '%%game%%';")
        local ret1 = query(sql)
        nodeid = (ret1 and ret1[1] and ret1[1].maxnodeid or 0) + 1
        if nodeid > 10000 then
            print("checkAndFixConf error4: nodeid invalid.", nodeid)
            return false
        end
        -- 修改dbconf.gamenodeid文件
        local cmd2 = string.format("grep \"dbconf.gamenodeid\" %s", filename)
        local ret2 = string.trim(io.popen(cmd2):read("*all") or "")
        if string.len(ret2) <= 0 then
            print("checkAndFixConf error5: cmd1 invalid.", cmd2)
            return false
        end
        local cmd3 = string.format("sed -i 's/%s/dbconf.gamenodeid = %d/g' %s", ret2, nodeid, filename)
        local ret3 = string.trim(io.popen(cmd3):read("*all") or "")
        print("checkAndFixConf do4 nodekey=", nodekey, "filename=", filename, "old gamenodeid=", cmd2, ret2, "new gamenodeid=", cmd3, ret3, string.trim(io.popen(cmd2):read("*all") or ""))
        -- 插入
        local sql = string.format([[INSERT INTO `conf_cluster` (`nodeid`, `nodekey`, `nodename`, `ip`, `web`, `listen`, `listennodename`, `port`, `type`)VALUES
            ('%d', '%s', '%s', '%s', '%s', '0.0.0.0', '%s', 20001, 3);]], nodeid, nodekey, string.format("nodegame_%d", nodeid), inIp, inIp, string.format("listen_nodegame_%d", nodeid))
        local ret4 = conn:execute(sql)
        print("checkAndFixConf do5 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "insert into conf_cluster ret=", ret4)
        if tonumber(ret4) ~= 1 then
            print("checkAndFixConf error6: insert into conf_cluster.", ret4)
            return false
        end
    end
    -- 更新/插入game_conf表
    local sql = string.format([[INSERT INTO `conf_debug` (`nodeid`, `ip`, `web`, `port`) VALUES ('%d', '127.0.0.1', '127.0.0.1', '%d');]], nodeid, 23001)
    local ret = conn:execute(sql)
    print("checkAndFixConf do6 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "insert into conf_debug ret=", ret)
    if tonumber(ret) ~= 1 then
        local sql = string.format([[UPDATE `conf_debug` SET `ip`='127.0.0.1', `web`='127.0.0.1', `port`='%d' WHERE `nodeid`='%d';]], 23001, nodeid)
        local ret = conn:execute(sql)
        print("checkAndFixConf do7 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "update conf_debug ret=", ret)
    end
    -- 更新/插入conf_gate表
    local sql = string.format([[INSERT INTO `conf_gate` (`nodeid`, `web`, `address`, `proxy`, `listen`, `port`) VALUES ('%d', '%s', '127.0.0.1', '%s', '0.0.0.0', '%d');]], nodeid, outIp, outIp, 24001)
    local ret = conn:execute(sql)
    print("checkAndFixConf do8 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "insert into conf_gate ret=", ret)
    if tonumber(ret) ~= 1 then
        local sql = string.format([[UPDATE `conf_gate` SET `web`='%s', `address`='127.0.0.1', `proxy`='%s', `listen`='0.0.0.0', `port`='%d' WHERE `nodeid`='%d';]], outIp, outIp, 24001, nodeid)
        local ret = conn:execute(sql)
        print("checkAndFixConf do9 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "update conf_gate ret=", ret)
    end
    -- 更新conf_ipwhitelist表
    local sql = string.format([[INSERT INTO `conf_ipwhitelist` (`nodeid`, `ipList`, `status`) VALUES ('%d', '127.0.0.1;', 0);]], nodeid)
    local ret = conn:execute(sql)
    print("checkAndFixConf do10 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "insert into conf_ipwhitelist ret=", ret)
    -- 更新/插入conf_kingdom表
    local sql = string.format([[INSERT INTO `conf_kingdom` (`kid`, `nodeid`, `status`, `startTime`, `isNew`) VALUES ('%d', '%d', 0, NOW(), 1);]], nodeid, nodeid)
    local ret = conn:execute(sql)
    print("checkAndFixConf do11 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "insert into conf_kingdom ret=", ret)
    if tonumber(ret) ~= 1 then
        local sql = string.format([[UPDATE `conf_kingdom` SET `nodeid`='%d', `status`='0', `isNew`='1' WHERE `kid`='%d';]], nodeid, nodeid)
        local ret = conn:execute(sql)
        print("checkAndFixConf do12 nodekey=", nodekey, "nodeid=", nodeid, "sql=", sql, "update conf_kingdom ret=", ret)
    end
    -- 关闭连接
    conn:close()
    env:close()
    return true
end

return checkAndFixConf(filename)
