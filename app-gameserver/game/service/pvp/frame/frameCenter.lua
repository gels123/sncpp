--[[
	帧同步服务中心
]]
local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local netpack = require "skynet.netpack"
local rudpsvr = require "rudpsvr"
local dbconf = require "dbconf"
local svrFunc = require "svrFunc"
local svrAddrMgr = require "svrAddrMgr"
local protoLib = require "protoLib"
local clientCmd = require "clientCmd"
local serviceCenterBase = require("serviceCenterBase2")
local frameCenter = class("frameCenter", serviceCenterBase)

-- 注册客户端指令
do
	require "frameCmd"
end

-- 初始化
function frameCenter:init(kid, idx, rudp)
	gLog.i("==frameCenter:init begin==", kid, idx, rudp)
	self.super.init(self, kid)

	-- 索引
	self.idx = idx
	-- 模式(1=rudp nil=tcp)
	self.rudp = rudp
	-- 模式(true=>客户端直连game服;false=>客户端直连global服;)
	self.mode = true
	-- 本服地址
	self.addr = skynet.self()

	-- 房间管理器
	self.userMgr = require("userMgr").new()
	-- 计时器管理器
	self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)

    gLog.i("==frameCenter:init end==", kid, idx, rudp)
end

-- 处理客户端消息
function frameCenter:dispatchMsg(fd, msg, sz)
	local user = self.userMgr:getFdMap(fd)
	if not user then
		gLog.w("frameCenter:dispatchMsg ignore", fd, sz)
		return
	end
	local callok, tp, cmd, args, rsp = pcall(function ()
		return protoLib:c2sDecode(msg, sz)
	end)
	--gLog.dump(args, "frameCenter:dispatchMsg tp="..tostring(tp)..",cmd="..tostring(cmd)..",rsp="..tostring(rsp)..",args=")
	if not callok or tp ~= "REQUEST" or not cmd then
		gLog.w("frameCenter:doAuth error1", fd, callok, tp, cmd, rsp, table2string(args))
		return
	end
	--if dbconf.DEBUG then
	--	gLog.d("room:dispatchMsg request uid=", user:getUid(), "cmd=", cmd, "args=", table2string(args))
	--end
	-- notice: may yield here, socket may close.
	local _, ret = xpcall(function()
		local f = assert(clientCmd[cmd], "agentCenter:dispatchMsg error, cmd= "..cmd.." is not found")
		if type(f) == "function" then
			return f(user, args or svrFunc.emptyTb)
		end
	end, svrFunc.exception)
	--if dbconf.DEBUG then
	--	gLog.d("agentCenter:dispatchMsg response uid=", user:getUid(), "cmd=", cmd, "ret=", table2string(ret))
	--end
	-- the return subid may change by multi request, check connect
	if rsp and fd then
		if self.rudp then
			rudpsvr.rudp_send(fd, rsp(ret))
		else
			socketdriver.send(fd, netpack.pack(rsp(ret)))
		end
	else
		gLog.w("agentCenter:dispatchMsg ignore", fd, user:getUid(), "cmd=", cmd, "ret=", ret)
	end
end

-- 登录
function frameCenter:login(uid, batId, subid)
	gLog.i("frameCenter:login enter=", uid, batId, subid)
	local room = self.userMgr:getRoom(batId, true)
	if not room then
		gLog.w("frameCenter:login err: createBattle first!", uid, batId, subid)
		if not dbconf.DEBUG then -- 正常是先创建房间, 再玩家进入登录进入战场, 测试服绕过
			return nil, gErrDef.Err_ROOM_NO_USER
		end
	end
	local user = self.userMgr:getUser(uid)
	user:login(uid, batId, subid)
	gLog.i("frameCenter:login end=", uid, batId, subid)
	return self.addr
end

-- 暂离
function frameCenter:afk(uid, batId, subid, flag)
	gLog.i("frameCenter:afk enter=", uid, batId, subid, flag)
	local user = self.userMgr:getUser(uid, true)
	if user then
		user:afk(flag)
		self.userMgr:delUser(uid)
		-- 算主动退出, 不能再重连进入
		local room = self.userMgr:getRoom(batId, true)
		if room then
			room:reqLeave(uid)
		end
		-- 回收内存
		-- skynet.send(skynet.self(),"debug", "GC")
	else
		gLog.i("frameCenter:afk ignore=", uid, batId, subid, flag)
	end
	gLog.i("frameCenter:afk end=", uid, batId, subid, flag)
end

-- 设置fd
function frameCenter:setFd(fd, uid, subid)
	if fd and uid and subid then
		gLog.i("frameCenter:setFd enter=", fd, uid, subid)
		local user = self.userMgr:getUser(uid, true)
		if user then
			-- 设置fd
			user:setFd(fd)
			-- checkin
			local ok = user:checkin(subid)
			gLog.i("frameCenter:setFd end=", fd, uid, subid, ok)
			return ok
		else
			gLog.w("frameCenter:setFd ignore=", fd, uid, subid)
		end
	end
end

-- 给客户端推送消息
function frameCenter:notifyMsg(uid, cmd, msg)
	pcall(function()
		if uid and cmd and msg then
			local user = self.userMgr:getUser(uid, true)
			if user then
				user:notifyMsg(cmd, msg)
			else
				gLog.d("frameCenter:notifyMsg ignore=", uid, cmd, msg)
			end
		end
	end)
end

-- 批量给客户端推送消息
function frameCenter:notifyMsgBatch(users, cmd, msg)
	pcall(function()
		if users and cmd and msg then
			for uid,v in pairs(users) do
				local user = self.userMgr:getUser(uid, true)
				if user then
					user:notifyMsg(cmd, msg)
				else
					--gLog.d("frameCenter:notifyMsgBatch ignore=", uid, cmd, msg)
				end
			end
		end
	end)
end

-- 创建一个战场
-- @batId 	战场ID
-- @users 	玩家ID列表 格式:users={[1201]={uid=1201,camp=0,}, [1202]={uid=1202,camp=1,}}
-- @rate 	帧率(默认值=16帧, 100ms/帧)
-- @time	最大战斗时长(默认值=300秒)
function frameCenter:createBattle(batId, users, rate, time)
	gLog.i("frameCenter:createBattle=", batId, users, rate, time)
	if type(batId) ~= "string" or not users or not next(users) or (rate and (rate <= 0 or rate > 50)) or (time and time <= 0) then
		gLog.w("frameCenter:createBattle err1", batId, users, rate, time)
		return false, gErrDef.Err_ILLEGAL_PARAMS
	end
	-- 检查是否同时存在攻守双方(0=攻方 1=守方 2=裁判)
	local camp0, camp1 = false, false
	for k,v in pairs(users) do
		if v.camp == 0 then
			camp0 = true
		elseif v.camp == 1 then
			camp1 = true
		end
	end
	if not (camp0 and camp1) then
		gLog.w("frameCenter:createBattle err2", batId, users, rate, time)
		return false, gErrDef.Err_ILLEGAL_PARAMS
	end
	local room = self.userMgr:getRoom(batId, true)
	if room then
		gLog.w("frameCenter:createBattle err3", batId, users, rate, time)
		return false, gErrDef.Err_ROOM_EXIST
	end
	room = self.userMgr:getRoom(batId)
	room:init(users, rate or 16, time or 300)

	return true, room:packInfo()
end

-- 请求准备完成
function frameCenter:reqPrepare(batId, uid)
	local room = self.userMgr:getRoom(batId, true)
	if not room then
		gLog.w("frameCenter:reqPrepare err1", batId, uid)
		return false, gErrDef.Err_ROOM_NOT_EXIST
	end
	return room:reqPrepare(uid)
end

-- 请求加载场景完成
function frameCenter:reqLoad(batId, uid)
	local room = self.userMgr:getRoom(batId, true)
	if not room then
		gLog.w("frameCenter:reqLoad err1", batId, uid)
		return false, gErrDef.Err_ROOM_NOT_EXIST
	end
	return room:reqLoad(uid)
end

-- 请求退出战场
function frameCenter:reqLeave(batId, uid)
	local room = self.userMgr:getRoom(batId, true)
	if not room then
		gLog.w("frameCenter:reqLeave err1", batId, uid)
		return false, gErrDef.Err_ROOM_NOT_EXIST
	end
	return room:reqLeave(uid)
end

-- 请求提交帧指令
function frameCenter:reqCommitCmd(batId, uid, cmd)
	local room = self.userMgr:getRoom(batId, true)
	if not room then
		gLog.w("frameCenter:reqCommitCmd err1", batId, uid)
		return false, gErrDef.Err_ROOM_NOT_EXIST
	end
	return room:reqCommitCmd(uid, cmd)
end

-- 计时器回调
function frameCenter:timerCallback(data)
	local id, timerType = data.id, data.timerType
	gLog.i("frameCenter:timerCallback=", id, timerType)
	if self.timerMgr:hasTimer(id, timerType) then
		if timerType == gPvpTimerType.status then
			local room = self.userMgr:getRoom(id, true)
			if room then
				room:timerCallback()
			else
				gLog.w("frameCenter:timerCallback ignore", id, timerType)
			end
		elseif timerType == gPvpTimerType.heartbeat then
			local user = self.userMgr:getUser(id, true)
			if user then
				local addr = svrAddrMgr.getSvr(svrAddrMgr.gatepvpSvr, self.kid)
				skynet.send(addr, "lua", "afk", id, user:getSubid(), 0)
			else
				gLog.w("frameCenter:timerCallback ignore", id, timerType)
			end
		else
			gLog.w("frameCenter:timerCallback ignore", id, timerType)
		end
	end
end

return frameCenter
