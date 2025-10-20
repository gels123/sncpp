local rankConf = class("rankConf")

-- redis排行榜key
rankConf.rankKey = "game:ranklist-%s-%s"

-- 排行榜类型(rankId不能重复)
rankConf.rankType =
{
	level = 1,	-- 等级排行榜(非全服排行榜)
}
rankConf.rankType2 = table.reverse(rankConf.rankType)

-- 哪些全服排行榜
rankConf.rankGlobal = {
	[rankConf.rankType.level] = false,
}

return rankConf