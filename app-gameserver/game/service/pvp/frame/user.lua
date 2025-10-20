--[[
	玩家
--]]
local skynet = require("skynet")
local socketdriver = require("skynet.socketdriver")
local rudpsvr = require("rudpsvr")
local netpack = require ("skynet.netpack")
local dbconf = require("dbconf")
local svrAddrMgr = require("svrAddrMgr")
local svrFunc = require("svrFunc")
local protoLib = require("protoLib")
local frameCenter = require("frameCenter"):shareInstance()
local user = class("user")

-- 构造
function user:ctor(uid)
	self.uid = assert(uid)  -- 玩家ID
	self.batId = nil  		-- 战场ID
	self.subid = nil        -- 玩家subid
	self.fd = nil           -- 套接字fd
	self.online = nil   	-- 是否在线
    self.checkinTime = nil 	-- checkin时间
    self.afkTime = nil 		-- afk时间
end

-- 获取王国ID
function user:getKid()
	return frameCenter.kid
end

-- 获取玩家ID
function user:getUid()
    return self.uid
end

-- 战场ID
function user:getBatId()
	return self.batId
end

-- 获取玩家subid
function user:getSubid()
    return self.subid or 0
end

-- 获取套接字fd
function user:getFd()
    return self.fd
end

-- 是否在线
function user:getOnline()
	return self.online
end

-- 玩家登录
function user:login(uid, batId, subid)
	gLog.i("==user:login begin==", uid, batId, subid, type(subid))
	self.uid = uid
	self.batId = batId
	self.subid = subid or self.subid
	self.afkTime = nil
	gLog.i("==user:login end==", uid, batId, subid)
	return true
end

-- 玩家切入
function user:checkin(subid)
	gLog.i("==user:checkin begin==", self.uid, self.subid, "subid=", subid, type(subid))
	self.subid = subid
	-- 设置在线
	self.online = true
	-- 设置checkin时间、afk时间
	self.checkinTime = svrFunc.systemTime()
	self.afkTime = 0
	if not self.rudp then -- tcp需要心跳
		frameCenter.timerMgr:updateTimer(self.uid, gPvpTimerType.heartbeat, svrFunc.systemTime()+gPvpHeartbeat)
	end
	gLog.i("==user:checkin end==", self.uid, self.subid)
	return true
end

-- 玩家暂离, agent服务还在
function user:afk(flag)
	gLog.i("==user:afk begin==", self.uid, self.subid, flag)
	-- 推送登出
	if self.online and flag then
		self:notifyMsg("notifyPvpLogout", {flag = flag or 0,})
	end
	-- 设置套接字fd
	self:setFd(nil)
	-- 设置离线
	self.online = false
	-- 设置afk时间
	self.afkTime = svrFunc.systemTime()
	gLog.i("==user:afk end==", self.uid, self.subid, flag)
	return true
end

-- 设置fd
function user:setFd(fd)
	gLog.i("user:setFd", self.uid, self.subid, "fd=", fd)
	-- 先移除fd关联
	if self.fd then
		frameCenter.userMgr:setFdMap(self.fd, nil)
	end
    self.fd = fd
	-- 增加玩家fd关联
	if self.fd then
		frameCenter.userMgr:setFdMap(self.fd, self)
	end
end

-- 给客户端推送消息(非登录消息用agentCenter:notifyMsg())
function user:notifyMsg(cmd, msg)
	--if dbconf.DEBUG then
	--	if cmd ~= "notifyPvpCmd" then
	--		gLog.d("user:notifyMsg uid=", self.uid, "cmd=", cmd, "msg=", table2string(msg))
	--	end
	--end
	if self.online and self.fd then
		local package = protoLib:s2cEncode(cmd, msg)
		if frameCenter.rudp then -- rudp
			rudpsvr.rudp_send(self.fd, package)
		else -- tcp
			if not socketdriver.send(self.fd, netpack.pack(package)) then
				gLog.w("user:notifyMsg socketdriver.send error", self.uid, self.fd, cmd)
			end
		end
	else
		gLog.w("user:notifyMsg ignore", self.uid, self.fd, cmd, msg)
	end
end

return user