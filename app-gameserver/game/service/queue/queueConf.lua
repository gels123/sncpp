--[[
    行军队列配置
]]
local queueConf = {}

-- 队列数量上限
queueConf.maxQueueNum = 4

-- 行军队列类型定义
queueConf.queueType = {
	collectMine = 1,        --采集队列
	killNpc = 2,            --打怪队列
	attackPlayer = 3,       --攻击玩家城堡队列
    massPlayer  = 4,        --集结攻击玩家城堡队列
    massSlave = 5,          --集结从属队列
    scout = 6,              --侦查队列
    backHome = 7,           --回城队列
    monsterAttack = 8,      --怪物攻城队列
}

-- 行军队列状态
queueConf.queueStatus = {
    massing		= 1, -- 集结中
    moving		= 2, -- 行军中
    staying		= 3, -- 驻扎中
    following 	= 4, -- 追随中（子队列抵达主队列城堡后的状态）
}

-- 队列计时器类型定义
queueConf.queueTimerType = {
	statusEndTime = "statusEndTime",  --状态结束时间
}

-- 队列索引字段定义
queueConf.queueIndexKey = {
    id = "id",
    uid = "uid",
    aid = "aid",
    toId = "toId",
    toUid = "toUid",
    queueType = "queueType",
}

-- 哪些队列类型是集结主队列
queueConf.massMainQueue = {
    [queueConf.queueType.massPlayer] = true,
}

-- 哪些队列类型不需要军队
queueConf.noArmyQueue = {
    [queueConf.queueType.scout] = true,       --侦查
}

-- 哪些队列类型返回时直接销毁
queueConf.noReturnQueue = {
    [queueConf.queueType.monsterAttack] = true, --怪物攻击
}

-- 队列伪移除时, 不删除的队列索引
queueConf.queueExceptKey = {
    [queueConf.queueIndexKey.id] = true,
    [queueConf.queueIndexKey.uid] = true,
    [queueConf.queueIndexKey.aid] = true,
}

return queueConf