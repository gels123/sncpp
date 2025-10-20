--[[
	运营日志相关定义
]]

-- 用户属性定义
gLogUserPro =
{
	------ 普通属性,每次覆盖 -------
	-- 登出时上报
	exp = "exp", --	角色经验
	level = "level", --	角色等级
	name = "name", --	角色名称
}

-- 事件类型定义
gLogEvent =
{
	--基础数据
	login = "login", --用户登录
	logout = "logout", --用户登出
	--邮件
	system_mail = "system_mail", --收到系统邮件
	get_mail_reward = "get_mail_reward", --领取邮件奖励
}

-- 中台日志tag定义
gLogEventTagZt =
{
	core = "core",
	custom = "custom",
	action = "action",
	sdklog = "sdklog",
	rum = "rum",
}