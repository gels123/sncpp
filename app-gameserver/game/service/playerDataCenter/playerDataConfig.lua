--[[
    玩家数据中心配置
--]]
local skynet = require "skynet"
local redisLib = require("redisLib")
local playerDataConfig = class("playerDataConfig")

-- redis数据类型（按业务分类）
gRedisType = {
    -- 玩家数据类型, 一个玩家对应一个哈希表, 存放多个模块数据
    player = {
        key = function(kid, id, module) return string.format("game-player-%s-%s", kid, id) end,
        get = function(key, id, module) return redisLib:hGet(key, module) end,
        set = function(key, id, module, data) return redisLib:hSet(key, module, data) end,
        del = function(key, id, module) redisLib:hDel(key, module) end
    },
    -- 联盟数据类型, 一个联盟对应一个哈希表, 存放多个模块数据
    alliance = {
        key = function(kid, id, module) return string.format("game-alliance-%s-%s", kid, id) end,
        get = function(key, id, module) return redisLib:hGet(key, module) end,
        set = function(key, id, module, data) return redisLib:hSet(key, module, data) end,
        del = function(key, id, module) redisLib:hDel(key, module) end
    },
    -- 王国数据类型, 一个王国对应一个哈希表, 存放多个模块数据
    kingdom = {
        key = function(kid, id, module) return string.format("game-kingdom-%s-%s", kid, id) end,
        get = function(key, id, module) return redisLib:hGet(key, module) end,
        set = function(key, id, module, data) return redisLib:hSet(key, module, data) end,
        del = function(key, id, module) redisLib:hDel(key, module) end
    },
    -- 通用数据类型, 一个王国-一个模块-一个ID对应一个key-value
    common = {
        key = function(kid, id, module) return string.format("game-%s-%s-%s", kid, module, id) end,
        get = function(key, id, module) return redisLib:get(key) end,
        set = function(key, id, module, data) return redisLib:set(key, data) end,
        del = function(key, id, module) redisLib:delete(key) end
    },
}

--[[
    模块配置
    @table [必填]数据表名
    @columns [需落地必填/不落地不填] 字段列表
    @keyColumns [需落地必填/不落地不填] 主键[索引]字段
    @dataColumns [需落地必填/不落地不填] 普通字段: 查询/更新时处理的字段，通常为{"data"}, 有配置则查询/更新将处理这些字段, 一般"data"字段放第1位
    @redisType [必填]本地redis数据类型, 参见gRedisType
    @queryResultCallback [选填]自定义返回数据处理方法，不配置使用默认处理方法
]]
playerDataConfig.moduleSettings = {
    -- 账号信息, 存到玩家哈希表, 且落库
    ["account"] = {
        ["table"] = "account",
        ["columns"] = {"_id", "user", "data"},
        ["keyColumns"] = {"_id", "user"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家缓存数据, 存到玩家哈希表, 且落库
    ["cacheplayer"] = {
        ["table"] = "cacheplayer",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家信息, 存到玩家哈希表, 且落库
    ["lordinfo"] = {
        ["table"] = "lordinfo",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家背包信息, 存到玩家哈希表, 且落库
    ["backpack"] = {
        ["table"] = "backpack",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家设置信息, 存到玩家哈希表, 且落库
    ["setting"] = {
        ["table"] = "setting",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家buff信息, 存到玩家哈希表, 且落库
    ["buffinfo"] = {
        ["table"] = "buffinfo",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 测试服调时间, 王国哈希表, 不落库
    ["faketime"] = {
        ["table"] = "faketime",
        ["redisType"] = gRedisType.common,
    },
    -- 邮件数据, 存到邮件哈希表, 且落库
    ["maildata"] = {
        ["table"] = "maildata",
        ["columns"] = {"mid", "content", "receivers", "mailtype", "settype", "cfgid", "expiretime", "isshared"},
        ["keyColumns"] = {"mid"},
        ["dataColumns"] = {"mid", "content", "receivers", "mailtype", "settype", "cfgid", "expiretime", "isshared"},
        ["redisType"] = gRedisType.common,
    },
    -- 玩家邮件信息, 存到玩家哈希表, 且落库
    ["mail"] = {
        ["table"] = "mail",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 共享邮件信息, 存到王国哈希表, 且落库
    ["mailshare"] = {
        ["table"] = "mailshare",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.kingdom,
    },
    -- 玩家地图信息, 存到玩家哈希表, 且落库
    ["mapinfo"] = {
        ["table"] = "mapinfo",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
    -- 玩家rpg信息, 存到玩家哈希表, 且落库
    ["rpginfo"] = {
        ["table"] = "rpginfo",
        ["columns"] = {"_id", "data"},
        ["keyColumns"] = {"_id"},
        ["dataColumns"] = {"data"},
        ["redisType"] = gRedisType.player,
    },
}

-- 获取本地redis数据类型
function playerDataConfig:getRedisType(module)
    return playerDataConfig.moduleSettings[module] and playerDataConfig.moduleSettings[module].redisType
end

-- 校验配置
function playerDataConfig:check()
    for module,v in pairs(playerDataConfig.moduleSettings) do
        assert(v.table, string.format("playerDataConfig:check error1: module=%s", module))
        assert(v.redisType, string.format("playerDataConfig:check error2: module=%s", module))
        if v.columns then -- 落库
            assert(v.columns and next(v.columns) and v.keyColumns and next(v.keyColumns) and v.dataColumns and next(v.dataColumns), string.format("playerDataConfig:check error3: module=%s", module))
            -- assert(#v.columns == (#v.keyColumns + #v.dataColumns), string.format("playerDataConfig:check error4: module=%s", module))
        else -- 不落库
           assert(v.keyColumns == nil and v.dataColumns == nil, string.format("playerDataConfig:check error5: module=%s", module))
        end
    end
    -- gLog.dump(playerDataConfig.moduleSettings, "playerDataConfig:check ok=", 10)
end

playerDataConfig:check()

return playerDataConfig