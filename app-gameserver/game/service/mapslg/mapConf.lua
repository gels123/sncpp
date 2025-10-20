local mapConf = class("mapConf")

--地图监听玩家数据字段
mapConf.player_field = {
	"kid",
	"name",
	"level",
	"castlelv",
	"head",
	"border",
	"skin",
    "skintime",
	"language",
	"guildid",
	"guildshort",
	"guildname",
	"guildbanner",
    "shieldover",
    "landshieldover",
    "score",
    "build",
    "offlinetime",
    "walllv",
    "resourceshieldover",
}
mapConf.player_field2 = table.reverse(mapConf.player_field)

--地图监听玩家数据字段哪些需要推送
mapConf.notify_player_field = {
    ["name"] = true,
    ["level"] = true,
    ["castlelv"] = true,
    ["head"] = true,
    ["border"] = true,
    ["skin"] = true,
    ["language"] = true,
    ["guildid"] = true,
    ["guildshort"] = true,
    ["guildname"] = true,
    ["shieldover"] = true,
    ["landshieldover"] = true,
    ["resourceshieldover"] = true,
    ["skintime"] = true,
    ["durability"] = true,
    ["wallst"] = true,
    ["wallet"] = true,
    ["walllv"] = true,
    ["burntime"] = true,
}

--地图监听玩家数据字段哪些需要同步更新城堡活物数据
mapConf.update_city_obj_field = {
    ["skin"] = true,
    ["skintime"] = true,
    ["burntime"] = true,
}

--地图类型定义
mapConf.map_type = {
	worldmap = 1, 	--世界地图(赛季1)
}

--地图类型
mapConf.mapid = mapConf.map_type.worldmap

--地图大小定义
mapConf.map_size = 1197

--地图块大小定义(9*9)
mapConf.map_block_size = 9

--地图块每行数量
mapConf.map_block_line = math.floor(1197/9)

--地图对象类型
mapConf.object_type = {
	playercity = 1, --玩家城市
	monster = 2, 	--野怪
	mine = 4, 		--资源矿
	chest = 5,		--宝箱
	boss = 6,		--boss
    checkpoint = 7, --关卡
    wharf = 8,		--码头
    city = 9,		--城市
    commandpost = 10,--联盟指挥所
    station = 11,   --车站
    buildmine = 12, --建筑矿
    fortress = 13,  --碉堡
    mill = 14,      --联盟磨坊/麦田
}

--怪物类型定义
mapConf.monster_type = {
	footman = 1, 		--步兵
	rider = 2, 			--骑兵
	archer = 3,			--弓兵
	radar = 4,			--雷达怪1
	radar_pinball = 5,	--雷达弹球怪(纯客户端怪)
	radar_x2vs = 6,	    --雷达x2对战玩法怪(纯客户端怪)
	radar_mini = 7,	    --雷达小游戏怪(纯客户端怪)
    radar_m = 8,		--雷达怪2
    radar_n = 9,		--雷达怪3
}

--雷达怪物类型定义
mapConf.monster_type_radar = {
    [mapConf.monster_type.radar] = true,
    [mapConf.monster_type.radar_m] = true,
    [mapConf.monster_type.radar_n] = true,
}

--资源矿类型定义
mapConf.mine_type = {
	food = 1,		--食物
	water = 2,		--水源
}

--建造矿类型定义
mapConf.buildmine_type = {
    init = 0,		--初始
    water = 1,		--水源
    food = 2,		--食物
    coin = 3,		--金币(电池)
    dead_factory = 4, --丧尸工坊
    atk_fortress = 5, --进攻堡垒
    def_fortress = 6, --防御堡垒
    guild_cornfield = 7, --联盟麦田
}

--建造矿类型定义2
mapConf.buildmine_type2 = table.reverse(mapConf.buildmine_type)

--建造矿类型定义
mapConf.buildmine_gather_res = {
    [mapConf.buildmine_type.water] = "Water",
    [mapConf.buildmine_type.food] = "Food",
    [mapConf.buildmine_type.coin] = "Coin",
}

--城市类型定义
mapConf.city_type = {
    small = 1,		--小城市
    mid = 2,		--中城市(大要塞)
    big = 3,		--大城市
    king = 4,		--皇城
}

--宝箱子类型定义
mapConf.chest_type = {
	radar_npc = 1,		--雷达怪npc
}

--boss子类型定义
mapConf.boss_type = {
    auto_refresh = 1,		--自动刷新类boss(精英野怪)
}

--地图对象大小
mapConf.object_size = {
    [mapConf.object_type.playercity] = {2, 2},
    [mapConf.object_type.monster] = {1, 1},
    [mapConf.object_type.mine] = {1, 1},
    [mapConf.object_type.chest] = {1, 1},
    [mapConf.object_type.boss] = {2, 2},
    [mapConf.object_type.checkpoint] = {3, 7, 7, 3},
    [mapConf.object_type.wharf] = {7, 3, 3, 5},
    [mapConf.object_type.city] = {
        [mapConf.city_type.small] = {5, 5},
        [mapConf.city_type.mid] = {5, 5},
        [mapConf.city_type.big] = {5, 5},
        [mapConf.city_type.king] = {7, 6},
    },
    [mapConf.object_type.commandpost] = {3, 3},
    [mapConf.object_type.station] = {5, 6},
    [mapConf.object_type.buildmine] = {1, 1},
    [mapConf.object_type.fortress] = {1, 1},
    [mapConf.object_type.mill] = {7, 6},
}

--以中心点作为坐标的建筑
mapConf.specil_obj_type = {
    [mapConf.object_type.checkpoint] = true,
    [mapConf.object_type.wharf] = true,
    [mapConf.object_type.city] = true,
    [mapConf.object_type.commandpost] = true,
    [mapConf.object_type.station] = true,
    [mapConf.object_type.mill] = true,
}

--搜怪
mapConf.search_object_type = {
	[mapConf.object_type.monster] = true,
	[mapConf.object_type.boss] = true,
	[mapConf.object_type.buildmine] = true,
}

--地图固有中立建筑类型
mapConf.origin_object_type = {
    [mapConf.object_type.checkpoint] = true,
    [mapConf.object_type.wharf] = true,
    [mapConf.object_type.city] = true,
    [mapConf.object_type.commandpost] = true,
    [mapConf.object_type.station] = true,
    [mapConf.object_type.buildmine] = true,
}

--地图可侦查的对象类型
mapConf.scout_object_type = {
    [mapConf.object_type.playercity] = true,
    --[mapConf.object_type.boss] = true,
    [mapConf.object_type.checkpoint] = true,
    [mapConf.object_type.wharf] = true,
    [mapConf.object_type.city] = true,
    [mapConf.object_type.commandpost] = true,
    [mapConf.object_type.station] = true,
    [mapConf.object_type.buildmine] = true,
    [mapConf.object_type.fortress] = true,
    [mapConf.object_type.mill] = true,
}

--地图个人拥有的的地图对象类型
mapConf.own_object_type = {
    [mapConf.object_type.playercity] = true,
    [mapConf.object_type.buildmine] = true,
    [mapConf.object_type.fortress] = true,
}

--地图有领地的地图对象类型, 1=代表城池  2=代表领地
mapConf.terr_object_type = {
    [mapConf.object_type.checkpoint] = 1,--关卡
    [mapConf.object_type.wharf] = 1,--码头
    [mapConf.object_type.city] = 1,--城市
    [mapConf.object_type.commandpost] = 2,--联盟指挥所
    [mapConf.object_type.station] = 2,--车站
    [mapConf.object_type.mill] = 2, --联盟磨坊
}

--地图有领地的地图对象类型区块内不刷怪
mapConf.terr_no_monster = {
    [mapConf.object_type.city] = true,--城市
    [mapConf.object_type.mill] = true,--联盟磨坊/麦田
}

--地图联盟建筑类型
mapConf.guild_build_type = {
    init = 0,       --
    center = 1,     -- 联盟总部
}

--地图联盟建筑状态
mapConf.guild_build_status = {
    init = 0,       -- 无
    building = 1,   -- 设置(建造)中
    giveup = 2,     -- 放弃(拆除)中
}

--哪些地图有领地的地图对象类型有首次开放时间
mapConf.first_open_object_type = {
    [mapConf.object_type.checkpoint] = true,
    [mapConf.object_type.city] = true,
}

--资源区域
mapConf.zone_type = {
	lower  = 1, --低级区域
	middle = 2, --中级区域
	senior = 3, --高级区域
    middle = 4, --中心区域
}

mapConf.lower_zone_type = {
    bgin = 101,
    endd = 106,
}

mapConf.aoi_type = {
	well  = 1, --外地图查看
	march = 2, --行军查看
}

-- 迁城类型
mapConf.move_type = {
	random 	= 1,	--主动随机迁城1
	appoint	= 2,	--高级迁城1
	guild 	= 3,	--联盟迁城
	randomsys = 4,	--系统随机迁城1
	newcross = 5,   --新手跨服迁城
    randomzone = 6,	--新手换区迁城1
}

-- 跨服迁城类型
mapConf.move_type_cross = {
    [mapConf.move_type.newcross] = true, --新手跨服迁城
}

-- 收藏类型
mapConf.collection_type = {
	source_svr = 1, -- 本服收藏夹
}

mapConf.build_status = {
    init = 1,                   -- [建筑矿、碉堡、领地建筑]初始/未开放/关闭中/统治中
    occupying = 2,              -- [建筑矿、碉堡、领地建筑]占领中/破坏中
    occupied = 3,               -- [建筑矿、碉堡、领地建筑]已占领, 尚未开始建造
    building = 4,               -- [建筑矿]建造中、停工
    settled = 5,                -- [建筑矿]建造完工且工程队入驻
    not_settle = 6,             -- [建筑矿]建造完工但工程队未入驻
    battle = 7,                 -- [领地建筑]战争中
}

-- 收藏标注z
mapConf.collection_mark = {
	general	= 1,	--普通
	friend 	= 2,	--朋友
	enemy	= 3,	--敌人
	monster = 4,	--怪物
}

mapConf.max_lineup = 3 --阵容上限
mapConf.master_index = 1 --阵容主位


-- 地图对象哪些字段更新后会推送客户端
mapConf.notifyAttrs = {
	uid = true, --[资源田]归属uid变化
    status = true, --[建筑矿]状态
    statusStartTime = true, --[建筑矿]状态开始时间
    statusEndTime = true, --[建筑矿]状态结束时间
    ownUid = true, --[建筑矿]建筑矿归属UID
    ownAid = true, --[建筑矿]建筑矿归属AID
    defenderCdTime = true, --[建筑矿]守军恢复截止时间
    cumuValue = true, --[建筑矿]累积值
    hp = true, --[碉堡、领地建筑、玩家城堡]归属玩家ID的截止时间
    ownTime = true, --[碉堡]归属玩家ID的截止时间
    annouceTime = true, --[领地建筑]宣战截止时间
    buildType = true, --[领地建筑]联盟建筑类型
    buildFlag = true, --[领地建筑]联盟建筑flag
    shieldover = true, --[玩家城堡、领地建筑]免战截止时间
    landshieldover = true, --[玩家城堡]领地盾截止时间
    isAct = true, --[领地建筑]是否激活
    skin = true,
    skintime = true,
    maxhp = true, --[联盟领地]最大耐久值[关卡、码头、城市、联盟指挥所、车站、联盟工坊]
    slaveNum = true,
    burntime = true,
}

-- 地图对象哪些字段更新后需要执行更多逻辑
mapConf.moreLogicAttrs = {
    ownUid = "ownUid", --[建筑矿]归属UID
    ownAid = "ownAid", --[建筑矿、领地建筑]归属AID
    buildType = "buildType", --[领地建筑]联盟建筑类型
    annouceTime = "annouceTime", --[领地建筑]宣战截止时间
    status = "status", --[建筑矿]状态
    isAct = "isAct", --[领地建筑]是否激活
    shieldover = "shieldover", --[建筑矿]保护罩
}

mapConf.moreLogicAttrsWith = {
    annouceTime = "annouceAid", --[领地建筑]宣战联盟ID

}

-- 地图领地对象哪些字段更新后会推送客户端
mapConf.notifyTerrAttrs = {
    status = true,
    statusStartTime = true,
    statusEndTime = true,
    isAct = true,
    buildType = true,
    buildFlag = true,
    buildTime = true,
    buildCdTime = true,
    annouceTime = true,
    maxhp = true,
}

mapConf.march_clsattr = {--行军类型对应属性
	[1] = "pve",--打野
	[2] = "collect",--采集
	[3] = "pvp",--PK
}

-- 队列类型定义
mapConf.queueType = {
	killMonster = 1, 	--打怪队列
	collectMine = 2, 	--采集队列(废弃)
	attackPlayer = 3, 	--攻击玩家城堡队列
	helpPlayer = 4, 	--援防玩家城堡队列
    massPlayer = 5,     --集结攻击玩家城堡队列
    massBoss = 7,       --集结攻击BOSS队列
    massSlave = 8,      --集结从属队列
    explore = 9,		--探索队列
    brigade = 10,		--工程队队列
    attackBuildMine = 11, --攻击建筑矿队列
    attackFortress = 12, --攻击碉堡队列
    massCity = 13,      --集结攻击城池/领地
    attackCity = 14, 	--单人攻击城池/领地
    helpBuildMine = 15, --援防建筑矿队列
    helpCity = 16, 	    --援防城池/领地
    massHelpCity = 17,  --集结援防城池/领地
}

-- 队列类型与地图对象类型对应关系
mapConf.queueType2ObjType = {
    [mapConf.queueType.collectMine] = mapConf.object_type.mine,
    [mapConf.queueType.killMonster] = mapConf.object_type.monster,
    [mapConf.queueType.attackPlayer] = mapConf.object_type.playercity,
    [mapConf.queueType.massPlayer] = mapConf.object_type.playercity,
    [mapConf.queueType.helpPlayer] = mapConf.object_type.playercity,
    [mapConf.queueType.massBoss] = mapConf.object_type.boss,
    [mapConf.queueType.massSlave] = mapConf.object_type.playercity,
    [mapConf.queueType.explore] = mapConf.object_type.chest,
    [mapConf.queueType.brigade] = mapConf.object_type.buildmine,
    [mapConf.queueType.attackBuildMine] = mapConf.object_type.buildmine,
    [mapConf.queueType.helpBuildMine] = mapConf.object_type.buildmine,
    [mapConf.queueType.attackFortress] = mapConf.object_type.fortress,
    [mapConf.queueType.massCity] = mapConf.terr_object_type,
    [mapConf.queueType.attackCity] = mapConf.terr_object_type,
    [mapConf.queueType.helpCity] = mapConf.terr_object_type,
    [mapConf.queueType.massHelpCity] = mapConf.terr_object_type,
}

-- 行军队列状态
mapConf.queueStatus = {
    massing		= 1, -- 集结
    moving		= 2, -- 行军
    building 	= 3, -- [只工程队队列]建造
    occupying 	= 4, -- 占领中
    staying		= 5, -- 驻扎中
    following 	= 6, -- 追随（子队列抵达主队列城堡后的状态）
    athome 	    = 7, -- [只工程队队列]闲置在家
}

-- 队列计时器类型定义
mapConf.queueTimerType = {
	statusEndTime = "statusEndTime",  --状态结束时间
}

-- 队列索引字段定义
mapConf.queueIndexKey = {
    id = "id",
    uid = "uid",
    aid = "aid",
    toId = "toId",
    toUid = "toUid",
    queueType = "queueType",
    mainQid = "mainQid",
}

-- 队列伪移除时, 不删除的队列索引
mapConf.queueExceptKey = {
    [mapConf.queueIndexKey.id] = true,
    [mapConf.queueIndexKey.uid] = true,
    [mapConf.queueIndexKey.aid] = true,
}

-- 队列下发给客户端的简要数据字段(服务器字段名-协议字段名)
mapConf.queueBriefKeys = {
    id = "id",
    ---- from ----
    uid = "uid",
    aid = "aid",
    queueType = "queueType",
    fromId = "fromId",
    fromX = "fromX",
    fromY = "fromY",
    ---- to -----
    toId = "toId",
    toX = "toX",
    toY = "toY",
    toMapType = "toMapType",
    toSubMapType = "toSubMapType",
    toUid = "toUid",
    ---- status ----
    status = "status",
    statusStartTime = "statusStartTime",
    statusEndTime = "statusEndTime",
    statusEndTimeOri = "statusEndTimeOri",
    ---- army ------
    army = "lineup",
    ---- line ----
    moveTimeSpan = "moveTimeSpan",
    ---- mass ----
    mainQid = "mainQid",
    slaveLineup = "slaveLineup",
    ---- settle ----
    isReturn = "isReturn",
    ---- other ----
    code = "code",
    guildbanner = "guildbanner",
    idx = "idx",
}

-- 队列下发给客户端的详细数据字段(服务器字段名-协议字段名)
mapConf.queueDetailKeys = {
    id = "id",
    ---- from ----
    uid = "uid",
    aid = "aid",
    queueType = "queueType",
    fromId = "fromId",
    fromX = "fromX",
    fromY = "fromY",
    ---- to -----
    toId = "toId",
    toX = "toX",
    toY = "toY",
    toMapType = "toMapType",
    toSubMapType = "toSubMapType",
    toLevel = "toLevel",
    toUid = "toUid",
    ---- status ----
    status = "status",
    statusStartTime = "statusStartTime",
    statusEndTime = "statusEndTime",
    statusEndTimeOri = "statusEndTimeOri",
    ---- army ------
    army = "lineup",
    ---- line ----
    moveTimeSpan = "moveTimeSpan",
    ---- mass ----
    mainQid = "mainQid",
    slaveLineup = "slaveLineup",
    ---- settle ----
    isReturn = "isReturn",
    ---- other ----
    createTime = "createTime",
    otherInfo = "otherInfo",
    code = "code",
    buildType = "buildType",
    occupyTime = "occupyTime",
    hitInv = "hitInv",
    idx = "idx",
    nextPlan = "nextPlan",
    brigadelv = "brigadelv",
    guildbanner = "guildbanner",
}

-- 哪些队列类型是集结主队列
mapConf.massMainQueue = {
    [mapConf.queueType.massPlayer] = true,
    [mapConf.queueType.massBoss] = true,
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- 集结主队列入驻后转化的队列类型
mapConf.massMainQueueChange = {
    [mapConf.queueType.attackCity] = mapConf.queueType.attackCity,
    [mapConf.queueType.massCity] = mapConf.queueType.attackCity,
    [mapConf.queueType.massHelpCity] = mapConf.queueType.attackCity,
    [mapConf.queueType.massSlave] = mapConf.queueType.attackCity,
}

-- 哪些队列类型是集结从属队列
mapConf.massSlaveQueue = {
    [mapConf.queueType.massSlave] = true,
}

-- 哪些队列属于联盟队列, 我退出联盟时我的这些队列将自动遣返
mapConf.needAllianceQueue = {
    [mapConf.queueType.helpPlayer] = true, --援防玩家城堡队列
    [mapConf.queueType.helpBuildMine] = true, --援防建筑矿队列
    [mapConf.queueType.massPlayer] = true, --集结攻击玩家城堡队列
    [mapConf.queueType.massBoss] = true,   --集结攻击BOSS队列
    [mapConf.queueType.massSlave] = true,  --集结从属队列
    [mapConf.queueType.massCity] = true,   --集结攻击城池/领地
    [mapConf.queueType.attackCity] = true, --单人攻击城池/领地
    [mapConf.queueType.helpCity] = true,   --援防城池/领地
    [mapConf.queueType.massHelpCity] = true, --集结援防城池/领地
}

-- 哪些队列属于联盟队列, 我退出联盟时朝向我的这些队列将自动遣返
mapConf.needAllianceQueue2 = {
    [mapConf.queueType.helpPlayer] = true, --援防玩家城堡队列
    [mapConf.queueType.helpBuildMine] = true, --援防建筑矿队列
}

-- 哪些队列属于联盟队列, 可以自己援防自己
mapConf.needAllianceQueue3 = {
    [mapConf.queueType.helpBuildMine] = true, --援防建筑矿队列
}

-- 哪些队列类型不需要士兵
mapConf.noArmyQueue = {
    [mapConf.queueType.explore] = true, --探索队列
    [mapConf.queueType.brigade] = true, --工程队队列
}

-- 哪些队列是玩家间战斗队列(会联盟积分)
mapConf.playerWarQueue = {
    [mapConf.queueType.attackPlayer] = true,
    [mapConf.queueType.massPlayer] = true,
    [mapConf.queueType.attackBuildMine] = true,
    [mapConf.queueType.helpBuildMine] = true,
    [mapConf.queueType.attackFortress] = true,
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- 哪些队列是玩家间战斗队列, 但策划排除
mapConf.playerWarQueueBak2 = {
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpBuildMine] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- 攻城战活动的玩家间战斗队列
mapConf.notCityWarQueue = {
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- [外交所]帮助我的城堡、非城堡的队列类型
mapConf.helpPlayerQueueType = {
    [mapConf.queueType.attackPlayer] = true,
    [mapConf.queueType.helpPlayer] = true,
    [mapConf.queueType.attackBuildMine] = true,
    [mapConf.queueType.helpBuildMine] = true,
    [mapConf.queueType.attackFortress] = true,

    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

--[外交所]我的联盟成员的援防领地队列信息
mapConf.helpTerrQueueType = {
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

--[外交所]援军的队列类型
mapConf.assistPlayerQueueType = {
    [mapConf.queueType.helpPlayer] = true,
    [mapConf.queueType.helpBuildMine] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
    [mapConf.queueType.attackCity] = true,    --massHelpCity集结到达目的后转换为attackCity
}

--[外交所]需要额外信息的援军的队列类型
mapConf.assistBriefExPlayerQueueType = {
    [mapConf.queueType.helpPlayer] = true,
    [mapConf.queueType.helpBuildMine] = true,
}

-- [战争大厅]攻击我的联盟成员的队列信息
mapConf.enemyQueueType = {
    [mapConf.queueType.attackPlayer] = true,
    [mapConf.queueType.attackBuildMine] = true,
    [mapConf.queueType.helpBuildMine] = true,
    [mapConf.queueType.attackFortress] = true,
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- [战争大厅]我的联盟成员的攻击队列信息
mapConf.attakQueueType = {
    [mapConf.queueType.attackPlayer] = true,
    [mapConf.queueType.attackBuildMine] = true,
    [mapConf.queueType.attackFortress] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.massBoss] = true,
    [mapConf.queueType.massSlave] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- [战争大厅]建筑矿、碉堡要有归属才会加到联盟战争
mapConf.attakQueueTypeSub = {
    [mapConf.queueType.attackBuildMine] = true,
    [mapConf.queueType.attackFortress] = true,
}

-- [战争大厅]集结队列必须放攻击列表
mapConf.attakQueueTypeSub2 = {
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

-- 哪些队列召回时, 会传code码
mapConf.recallQueueCode = {
    [mapConf.queueType.attackPlayer] = true,
    [mapConf.queueType.brigade] = true,
    [mapConf.queueType.massBoss] = true,
    [mapConf.queueType.massCity] = true,
    [mapConf.queueType.attackCity] = true,
    [mapConf.queueType.helpCity] = true,
    [mapConf.queueType.massHelpCity] = true,
}

--世界地图AOI配置
mapConf.world_aoi_confs =
{
    [1] = {
        lv = 1,
        slv = 1, --表现层1级缩放
        offset = 18,
        offsetMax = 36, --最远直径36=4*9
        mapTypes = {
            [mapConf.object_type.playercity] = true,
            [mapConf.object_type.monster] = true,
            [mapConf.object_type.mine] = true,
            [mapConf.object_type.chest] = true,
            [mapConf.object_type.boss] = true,
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.commandpost] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.buildmine] = true,
            [mapConf.object_type.fortress] = true,
            [mapConf.object_type.mill] = true,
        },
        queueTypes = {},
        queueOffsetMax = 54,
    },
    [2] = {
        lv = 2,
        slv = 2, --表现层2级缩放
        offset = 27,
        offsetMax = 54, --最远直径54=6*9
        mapTypes = {
            [mapConf.object_type.playercity] = true,
            [mapConf.object_type.monster] = true,
            [mapConf.object_type.mine] = true,
            [mapConf.object_type.chest] = true,
            [mapConf.object_type.boss] = true,
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.commandpost] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.buildmine] = true,
            [mapConf.object_type.fortress] = true,
            [mapConf.object_type.mill] = true,
        },
    },
    [3] = {
        lv = 3,
        slv = 3, --表现层3级缩放
        offset = 45,
        offsetMax = 90, --最远直径90=10*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [4] = {
        lv = 4,
        slv = 3, --表现层3级缩放
        offset = 63,
        offsetMax = 126, --最远直径108=14*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [5] = {
        lv = 5,
        slv = 3, --表现层3级缩放
        offset = 81,
        offsetMax = 162, --最远直径162=18*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [6] = {
        lv = 6,
        slv = 4, --表现层4级缩放
        offset = 99,
        offsetMax = 198, --最远直径198=22*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [7] = {
        lv = 7,
        slv = 4, --表现层4级缩放
        offset = 135,
        offsetMax = 270, --最远直径270=30*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [8] = {
        lv = 8,
        slv = 4, --表现层4级缩放
        offset = 171,
        offsetMax = 342, --最远直径342=38*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [9] = {
        lv = 9,
        slv = 4, --表现层4级缩放
        offset = 207,
        offsetMax = 414, --最远直径414=46*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    },
    [10] = {
        lv = 10,
        slv = 4, --表现层4级缩放
        offset = 243,
        offsetMax = 486, --最远直径486=54*9
        mapTypes = {
            [mapConf.object_type.checkpoint] = true,
            [mapConf.object_type.wharf] = true,
            [mapConf.object_type.city] = true,
            [mapConf.object_type.station] = true,
            [mapConf.object_type.mill] = true,
            [mapConf.object_type.commandpost] = true,
        },
    }
}

mapConf.GetGuildEXPType = {
    allKill     = 1,    --全部击杀
    Kill        = 2,    --击杀多少获得多少
}

return mapConf
