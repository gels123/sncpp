local mailConf = class("mailConf")

-- 邮件类型
mailConf.mailTypes =
{
	typeNormal		 		= 0,	-- 普通邮件
}

-- 邮件集合类型
mailConf.setTypes =
{
	setAlliance		 		= 1,	-- 联盟
	setActivity				= 2,	-- 活动
	setSystem		 		= 3,	-- 系统
	setCollect	 			= 4,	-- 收藏
}
mailConf.setTypesRev = table.reverse(mailConf.setTypes)

-- 邮件集合-邮件数量上限
mailConf.setTypesLimit =
{
	[mailConf.setTypes.setAlliance]		 		= 50,	-- 联盟
	[mailConf.setTypes.setActivity]		 		= 50,	-- 活动
	[mailConf.setTypes.setSystem]		 		= 100,	-- 系统
	[mailConf.setTypes.setCollect]		 		= 50,	-- 收藏
}

-- 共享邮件数量上限
mailConf.shareMailLimit = 50

-- 邮件默认过期时间(二个月)
mailConf.expiretime = 2 * 30 * 86400

-- 邮件数据释放时间(半小时)
mailConf.mailexpiretime = 1800

-- 清理mysql过期邮件时间
mailConf.clearMysqlTime = 43200

-- 哪些邮件获取简要信息时自动全部已读
mailConf.viewMailWhenReqBrief =
{
	[mailConf.setTypes.setCollect] = true
}

-- 邮件计时器类型
mailConf.timerType =
{
	shareExpire = "shareExpire", -- 共享邮件过期
	playerExpire = "playerExpire", -- 玩家邮件过期
	playerRelease = "playerRelease", -- 玩家邮件释放
	mailRelease = "mailRelease", -- 邮件数据释放
	mailExpire = "mailExpire", -- 邮件数据过期
}

-- 测试服特殊配置
if dbconf.DEBUG then
	mailConf.expiretime = 5 * 86400
	mailConf.mailexpiretime = 300
	mailConf.clearMysqlTime = 1800
end

return mailConf