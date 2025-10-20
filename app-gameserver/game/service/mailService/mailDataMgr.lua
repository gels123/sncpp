--[[
	邮件数据管理
--]]
local skynet = require("skynet")
local mailConf = require("mailConf")
local dbconf = require("dbconf")
local svrFunc = require("svrFunc")
local gLog = require("newLog")
local mailDataC = require("mailData")
local playerDataLib = require("playerDataLib")
local snowflake = require("snowflake")
local mailCenter = require("mailCenter"):shareInstance()
local mailDataMgr = class("mailDataMgr")

function mailDataMgr:ctor()
	-- 邮件列表
	self.mailList = {}
end

-- 初始化
function mailDataMgr:init()
	-- mailCenter.timerMgr:updateTimer(-2, mailConf.timerType.mailExpire, 1)
end

-- 默认邮件数据
function mailDataMgr:defaultMailData(mid, sender, receivers, mailtype, settype, cfgid, content, expiretime, isshared)
	return {
		mid = mid,						-- 邮件id
		sender = sender or 0,			-- 发送者
		receivers = table.reverse(receivers or {}),	-- 接收者
		mailtype = mailtype or 0,		-- 邮件类型
		settype = settype or 0,			-- 邮件集合类型
		cfgid = cfgid or 0,				-- 邮件配置id
		expiretime = (expiretime or 0) <= 0 and 0 or (svrFunc.systemTime() + (mailConf.expiretime or 0)), -- 过期时间
		isshared = isshared,			-- 是否共享邮件
		content = content or {},		-- 邮件内容
	}
end

-- 工厂方法, 创建邮件, 邮件id是自增长/雪花算法ID
function mailDataMgr:create(sender, receivers, mailtype, settype, cfgid, content, expiretime, isshared)
	-- 获取自增mid
	local mid = nil --snowflake.nextid() -- 共享邮件ID需要自增, 雪花ID不合适 
	if dbconf.dbtype == "mongodb" then
		local r = (isshared and 1 or math.random(1, playerDataLib.serviceNum))
		local ret = playerDataLib:executeSql(mailCenter.kid, r, "findAndModify", "maildata_seq", {
			query = {["_id"] = "maildata_seq" },
			update = {["$inc"] = {nextid = 1}},
			new = true,
		})
		-- gLog.dump(ret, "accountHelper:createAccount findAndModify ret=")
		if not (ret and not ret.err and ret.value and ret.value.nextid) then
			gLog.e("mailDataMgr:create error1")
			return false, gErrDef.Err_MAIL_CREATE
		end
		mid = ret.value.nextid
	elseif dbconf.dbtype == "mysql" then
		local r = (isshared and 1 or math.random(1, playerDataLib.serviceNum))
		local ret = playerDataLib:executeSql(mailCenter.kid, r, "insert into maildata(mid,expiretime) VALUES('0','0')")
		if not ret or not ret.insert_id then
			gLog.e("mailDataMgr:create error2")
			return false, gErrDef.Err_MAIL_CREATE
		end
		mid = ret.insert_id
	else
		assert(false, "dbtype error"..tostring(dbconf.dbtype))
	end
	-- 创建邮件
	local dbdata = self:defaultMailData(mid, sender, receivers, mailtype, settype, cfgid, content, expiretime, isshared)
    local mailData = mailDataC.new(mid, dbdata)
	mailData:updateDB()
	-- gLog.dump(dbdata, "mailDataMgr:create dbdata=", 10)
    -- 插入
	self:insert(mailData)
	--
	return true, mailData
end

-- 插入
function mailDataMgr:insert(mailData)
	local mid = mailData:getAttr("mid")
	if not self.mailList[mid] then
		self.mailList[mid] = mailData
		mailCenter.timerMgr:updateTimer(mid, mailConf.timerType.mailRelease, svrFunc.systemTime()+mailConf.mailexpiretime)
	end
end

-- 释放
function mailDataMgr:release(mid)
	if self.mailList[mid] then
		gLog.d("mailDataMgr:release", mid)
		self.mailList[mid] = nil
		mailCenter.timerMgr:updateTimer(mid, mailConf.timerType.mailRelease, nil)
	end
	--gLog.dump(self, "mailDataMgr:release self=")
end

-- 删除
function mailDataMgr:remove(mid, uid, force)
	if mid then
		local mailData = self.mailList[mid] or self:query(mid)
		if mailData then
			local ok = mailData:remove(uid, force)
			gLog.i("mailDataMgr:remove", mid, uid, force, "ok=", ok)
			self:release(mid)
		else
			gLog.w("mailDataMgr:remove error", mid, uid, force)
		end
	end
end

-- 查找
function mailDataMgr:query(mid)
	-- 先本地查找
	if self.mailList[mid] then
		mailCenter.timerMgr:updateTimer(mid, mailConf.timerType.mailRelease, svrFunc.systemTime()+mailConf.mailexpiretime)
		return self.mailList[mid]
	end
	-- 去数据库查找拉起
	local mailData = mailDataC.new(mid)
	if mailData:init() then
		self:insert(mailData)
		return mailData
	end
end

-- 定时删除过期邮件回调
function mailDataMgr:onExpireMailCallback()
	-- gLog.i("mailDataMgr:onExpireMailCallback begin=", mailCenter.kid)
	-- local time1 = skynet.time()
	-- xpcall(function()
	-- 	-- 防止大事务锁表, 慢慢删
	-- 	if dbconf.dbtype == "mysql" then
	-- 		local expiretime = math.floor(time1)
	-- 		local sql = string.format("delete from maildata where expiretime > '0' and expiretime < '%s' limit 100", expiretime)
	-- 		while(true) do
	-- 			local ret = playerDataLib:executeSql(mailCenter.kid, math.random(1, 16), sql)
	-- 			--gLog.dump(ret, "mailDataMgr:onExpireMailCallback ret=")
	-- 			if type(ret) == "table" and not ret.err and not ret.badresult and tonumber(ret.affected_rows or 0) > 0 then
	-- 				if dbconf.DEBUG then
	-- 					skynet.sleep(1)
	-- 				else
	-- 					skynet.sleep(7700)
	-- 				end
	-- 			else
	-- 				break
	-- 			end
	-- 		end
	-- 	else
	-- 		gLog.w("mailDataMgr:onExpireMailCallback ignore dbtype=", dbconf.dbtype)
	-- 	end
	-- end, svrFunc.exception)
	-- mailCenter.timerMgr:updateTimer(-2, mailConf.timerType.mailExpire, svrFunc.systemTime()+mailConf.clearMysqlTime)
	-- local time2 = skynet.time()
	-- gLog.i("mailDataMgr:onExpireMailCallback end=", mailCenter.kid, "time=", time2-time1)
end

return mailDataMgr
