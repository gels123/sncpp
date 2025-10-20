--[[
	服务地址管理
]]
local skynet = require("skynet.manager")
local svrAddrMgr = {}

--------------------------- 服务名称 BEGIN -------------------------
-- 配置数据DB服务名称
svrAddrMgr.confDBSvr = ".mysql_confdb"
-- 游戏数据DB服务名称
svrAddrMgr.gameDBSvr = ".mysql_gamedb"
-- 本地REDIS服务名称(主)
svrAddrMgr.redisSvr = ".redisSvr"
-- 公共REDIS服务名称(主)
svrAddrMgr.publicRedisSvr = ".publicRedisSvr"
-- 本地配置服务名称
svrAddrMgr.localData = ".localData"
-- 日志服务名称
svrAddrMgr.newLoggerSvr = ".newLoggerSvr"
-- 启动服务名称
svrAddrMgr.startSvr = ".startSvr@%d"
-- 启动服务名称(登录服&全局服)
svrAddrMgr.startSvrG = ".startSvr"
-- 数据中心服务
svrAddrMgr.dataCenterSvr = ".dataCenterSvr@%d@%d"
-- 协议共享服务名称
svrAddrMgr.sprotoSvr = ".sprotoSvr"
-- 网关服务名称
svrAddrMgr.gateSvr = ".gateSvr@%d"
-- 登陆服务名称
svrAddrMgr.loginMasterSvr = ".loginMasterSvr"
-- es搜索服务名称
svrAddrMgr.elasticSearchSvr = ".elasticSearchSvr"
-- 寻路服务名称
svrAddrMgr.searchSvr = ".searchSvr@%d@%d"
-- 玩家代理池服务
svrAddrMgr.agentPoolSvr = ".agentPoolSvr@%d"
-- 联盟服务
svrAddrMgr.allianceSvr = ".allianceSvr@%d"
-- 地图服务
svrAddrMgr.mapSvr = ".mapSvr@%d@d"
-- 行军队列服务
svrAddrMgr.queueSvr = ".queueSvr@%d"
-- pvp网关服务名称
svrAddrMgr.gatepvpSvr = ".gatepvpSvr@%d"
-- 帧同步服务名称
svrAddrMgr.frameSvr = ".frameSvr@%d@%d"
-- 运营日志打点服务名称
svrAddrMgr.logSvr = ".logSvr@%d"
-- 事件服务
svrAddrMgr.eventSvr = ".eventSvr@%d"
-- 邮件服务
svrAddrMgr.mailSvr = ".mailSvr@%d@%d"
-- 报错信息通知服务
svrAddrMgr.alertSvr = ".alertSvr"
-- 谷歌翻译服务
svrAddrMgr.googleTranslateSvr = ".googleTranslateSvr@%d"
-- 缓存服务
svrAddrMgr.cacheSvr = ".cacheSvr@%d"
-- 公共服务名称(global服)
svrAddrMgr.commonSvr = ".commonSvr@%d@%d"
-- agent服务名称(global服)
svrAddrMgr.agentSvrGlobal = ".agentSvr@%d@%d"
-- 视野服务
svrAddrMgr.aoiSvr = ".aoiSvr@%d"
-- 排行榜服务
svrAddrMgr.rankSvr = ".rankSvr@%d@%d"

--------------------------- 服务名称 END ---------------------------

--------------------------- 服务地址操作 API BEGIN -------------------------
-- 获取服务名称
function svrAddrMgr.getSvrName(key, kid, otherId)
	if kid and otherId then
		return string.format(key, kid, otherId)
	elseif kid then
		return string.format(key, kid)
	elseif otherId then
		return string.format(key, otherId)
	end
	return key
end

-- 设置王国服务地址
function svrAddrMgr.setSvr(address, key, kid, otherId)
	key = svrAddrMgr.getSvrName(key, kid, otherId)
	skynet.name(key, address)
end

-- 获取服务地址
function svrAddrMgr.getSvr(key, kid, otherId)
	key = svrAddrMgr.getSvrName(key, kid, otherId)
	-- 获取本节点服务地址
	local address = skynet.localname(key)
	-- 若非本节点服务地址, 则跨节点获取服务地址
	if not address and kid then
		local svrConf = require("svrConf")
		address = svrConf:getSvrProxyGame(kid, key)
	end
	if not address then
		local errMsg = string.format("svrAddrMgr.getSvr error: %s %s %s", key, kid, otherId)
		skynet.error(errMsg)
	end
	return address
end
--------------------------- 服务地址操作 API END ---------------------------

return svrAddrMgr