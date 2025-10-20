--[[
	玩家邮件管理
]]
local skynet = require("skynet")
local svrFunc = require "svrFunc"
local mailConf = require "mailConf"
local gLog = require "newLog"
local agentLib = require("agentLib")
local playerDataLib = require("playerDataLib")
local playerMailC = require("playerMail")
local mailCenter = require("mailCenter"):shareInstance()
local playerMailMgr = class("playerMailMgr")

function playerMailMgr:ctor()
	-- 成员列表
	self.memList = {}
	-- 在线玩家列表
	self.userOnline = {}
end

-- 排队
function playerMailMgr:queue(uid, f)
	local sq = mailCenter:getSq(uid)
	return sq(f)
end

-- 获取玩家邮件 isMem=是否只查找内存
function playerMailMgr:getPlayerMail(uid, isMem)
	return self:queue(uid, function ()
		if not self.memList[uid] and not isMem then
			agentLib:call(mailCenter.kid, "checkLock", uid)
			local kid = playerDataLib:getKidOfUid(mailCenter.kid, uid)
			if kid ~= mailCenter.kid then
				gLog.w("playerMailMgr:getPlayerMail fail", uid, kid, mailCenter.kid)
				return
			end
			self.memList[uid] = playerMailC.new(uid)
			self.memList[uid]:init()
			-- 更新释放计时器
			mailCenter.timerMgr:updateTimer(uid, mailConf.timerType.playerRelease, svrFunc.systemTime()+gAgentFreeTime)
		end
		return self.memList[uid]
	end)
end

--[[
	释放玩家邮件
--]]
function playerMailMgr:releasePlayerMail(uid)
	gLog.i("playerMailMgr:releasePlayerMail", uid)
	self:queue(uid, function ()
		self.userOnline[uid] = nil
		self.memList[uid] = nil
	end)
	mailCenter:delSq(uid)
	--gLog.dump(self, "playerMailMgr:releasePlayerMail self=")
end

-- 登陆
function playerMailMgr:login(uid)
	gLog.i("playerMailMgr:login uid=", uid)
	local time = skynet.time()
	self:getPlayerMail(uid) --拉起数据
	local cost = skynet.time() - time
	if cost > 1 then
		gLog.w("playerMailMgr:login timeout!", uid, cost)
	end
	return true
end

-- checkin
function playerMailMgr:checkin(uid)
	gLog.i("playerMailMgr:checkin uid=", uid)
	local time = skynet.time()
	local playerMail = self:getPlayerMail(uid)
	if playerMail then
		self:queue(uid, function()
			-- 更新在线玩家列表
			self.userOnline[uid] = true
			-- 登陆
			playerMail:checkin()
			-- 更新释放计时器
			mailCenter.timerMgr:updateTimer(uid, mailConf.timerType.playerRelease, nil)
		end)
	end
	local cost = skynet.time() - time
	if cost > 1 then
		gLog.w("playerMailMgr:checkin timeout!", uid, cost)
	end
	return true
end

-- 登出
function playerMailMgr:afk(uid)
	gLog.i("playerMailMgr:afk uid=", uid)
	local time = skynet.time()
	local playerMail = self:getPlayerMail(uid, true)
	if playerMail then
		self:queue(uid, function()
			-- 更新在线玩家列表
			self.userOnline[uid] = nil
			-- 登出
			playerMail:afk()
			-- 更新释放计时器
			mailCenter.timerMgr:updateTimer(uid, mailConf.timerType.playerRelease, svrFunc.systemTime()+gAgentFreeTime)
		end)
	end
	local cost = skynet.time() - time
	if cost > 1 then
		gLog.w("playerMailMgr:afk timeout!", uid, cost)
	end
end

-- 登出
function playerMailMgr:logout(uid)
	gLog.i("playerMailMgr:logout uid=", uid)
	local time = skynet.time()
	local playerMail = self:getPlayerMail(uid, true)
	if playerMail then
		mailCenter.timerMgr:updateTimer(uid, mailConf.timerType.playerRelease, 0)
		self:releasePlayerMail(uid)
	end
	local cost = skynet.time() - time
	if cost > 1 then
		gLog.w("playerMailMgr:logout timeout!", uid, cost)
	end
end

-- 添加新邮件
function playerMailMgr:addNewMail(uid, mid, mailtype, settype, cfgid, hasExtra, brief, expiretime, isshared)
	gLog.d("playerMailMgr:addNewMail", uid, mid, mailtype, settype, cfgid, hasExtra, brief, expiretime, isshared)
	local time = skynet.time()
	local playerMail = self:getPlayerMail(uid)
	local ok, code = nil, nil
	if playerMail then
		self:queue(uid, function()
			ok, code = playerMail:addNewMail(mid, mailtype, settype, cfgid, hasExtra, brief, expiretime, isshared)
		end)
	end
	local cost = skynet.time() - time
	if cost > 1 then
		gLog.w("playerMailMgr:addNewMail timeout!", uid, cost, mid, mailtype, settype, hasExtra, expiretime, isshared)
	end
	return ok, code
end

-- 获取在线玩家列表
function playerMailMgr:getUserOnline()
	return self.userOnline
end

return playerMailMgr
