--[[
	邮件服务对外接口
]]
local skynet = require ("skynet")
local json = require "json"
local mailConf = require "mailConf"
local svrAddrMgr = require ("svrAddrMgr")
local agentLib = require ("agentLib")
local playerDataLib = require ("playerDataLib")
local mailLib = class("mailLib")

-- 服务数量
mailLib.serviceNum = 4

-- 获取服务地址
function mailLib:getAddress(kid, uid)
	return svrAddrMgr.getSvr(svrAddrMgr.mailSvr, kid, uid%mailLib.serviceNum + 1)
end

-- call调用
function mailLib:call(kid, uid, ...)
	return skynet.call(self:getAddress(kid, uid), "lua", ...)
end

-- send调用
function mailLib:send(kid, uid, ...)
	skynet.send(self:getAddress(kid, uid), "lua", ...)
end

-- 登录
function mailLib:login(kid, uid)
	return self:call(kid, uid, "login", uid)
end

-- checkin
function mailLib:checkin(kid, uid)
	return self:call(kid, uid, "checkin", uid)
end

-- 登出
function mailLib:afk(kid, uid)
	self:call(kid, uid, "afk", uid)
end

-- 登出
function mailLib:logout(kid, uid)
	self:call(kid, uid, "logout", uid)
end

--[[
	发送普通邮件
	@sender  	发送者(系统填0,玩家填uid)
	@cfgid 		邮件配置ID
	@content	邮件数据(eg. {brief={简要标题数组}, more={array=更多信息数组,k=v,...}, text="纯文本", extra={附件table}})
	@expiretime	邮件过期时间
	eg:
		mailLib:sendMail(1, 0, {1201}, 111, {brief={1,"name1","itemId(@)101"}, more={rank=1,list={}}, extra={items={{id=5001,count=1}}}})
]]
function mailLib:sendMail(kid, sender, receivers, cfgid, content, expiretime)
	skynet.fork(function()
		content = content or {}
		content.brief = type(content.brief) == "table" and json.encode(content.brief) or ""
		content.more = type(content.more) == "table" and json.encode(content.more) or ""
		assert(receivers and #receivers > 0 and cfgid)
		-- 检查迁服锁, 玩家迁服过程时, 等待迁服结束再往新的kid发送邮件
		--local curkid = nil
		--for _,uid in ipairs(receivers) do
		--	agentLib:call(kid, "checkLock", uid)
		--	curkid = playerDataLib:getKidOfUid(kid, uid)
		--	if curkid and curkid > 0 then
		--		skynet.send(self:getAddress(curkid, uid), "lua", "sendMail", sender or 0, {uid}, mailConf.mailTypes.typeNormal, 1, cfgid, content, expiretime)
		--	end
		--end
		-- 迁服锁内执行发邮件
		for _,uid in ipairs(receivers) do
			uid = tonumber(uid)
			agentLib:send(kid, "sendMail", uid, sender or 0, {uid}, mailConf.mailTypes.typeNormal, 1, cfgid, content, expiretime)
		end
	end)
end

-- 发送共享邮件
function mailLib:sendShareMail(kid, sender, cfgid, content, expiretime, castleLv, logoutTime, isNewUsr)
	skynet.fork(function()
		content = content or {}
		content.brief = type(content.brief) == "table" and json.encode(content.brief) or ""
		content.more = type(content.more) == "table" and json.encode(content.more) or ""
		for idx=1,mailLib.serviceNum,1 do
			self:send(kid, idx, "sendShareMail", sender, mailConf.mailTypes.typeNormal, 1, cfgid, content, expiretime, castleLv, logoutTime, isNewUsr)
		end
	end)
end

return mailLib
