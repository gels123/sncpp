--[[
	帧同步服务中心
	战场流程:
		[服务器]创建战场, 并推送消息`创建战场成功,可以调用请求准备完成接口`, status=1 =>
		[客户端]弹出准备界面, 点准备时, 调用请求准备完成接口 =>
		[服务器]所有人都准备完成时, 推送消息`所有人都已准备完成, 可以开始加载场景`, status=2 =>
		[客户端]开始加载场景, 完成时, 调用请加载场景完成接口 =>
		[服务器]所有人加载场景完成时, 推送消息`开始游戏`, 开始跑逻辑帧 status=3 =>
		[客户端] 开始游戏、跑逻辑帧
		[客户端] ...
		[客户端] ... 请求操作指令、收到全员帧指令推送... =>
		[客户端] ...
		[服务器]推送游戏结束, 等待结算(status=4) =>
		[服务器]结算结束, 删除战场
]]
local skynet = require "skynet"
local svrFunc = require "svrFunc"
local frameCenter = require("frameCenter"):shareInstance()
local room = class("room")

-- 战场状态
local eBatStatus = {
	eInit = 0,				-- 房间:无										玩家: 初始
	eWaitPrepare = 1,		-- 房间:创建战场成功, 等待所有人准备完成				玩家: 已准备完成
	eWaitLoad = 2,			-- 房间:所有人已准备完成, 等待所有人加载场景完成		玩家: 已加载场景完成
	eGame = 3,				-- 房间:所有人已加载场景完成, 跑逻辑帧中				玩家: 跑逻辑帧中
	eSettle = 4,			-- 房间:游戏结束, 等待结算状态
	eFree = 5,				-- 房间:已结束释放								玩家: 主动退出战场(认输)/已结束释放
}

-- 构造
function room:ctor(batId)
	assert(type(batId) == "string")
	self.batId = batId		-- 战场ID
	self.status = eBatStatus.eWaitPrepare -- 状态
	self.users = nil		-- 玩家ID数组
	self.info = {}			-- 相关信息
	self.rate = 0			-- 帧率
	self.tick = 0			-- 每帧时长(单位=10ms=1/100s)
	self.f = 0				-- 当前帧数
	self.fmax = 0			-- 最大帧数
	self.time = 0			-- 最大战斗时间
	self.isEnd = false		-- 是否已结束
	self.msg = nil	 		-- 帧消息
end

-- 初始化
function room:init(users, rate, time)
	gLog.d("room:init=", self.batId, users, rate, time)
	self.status = eBatStatus.eWaitPrepare
	self.users = users
	for uid,v in pairs(users) do
		self.info[uid] = {
			uid = uid,
			camp = v.camp or 0, -- 0=攻方 1=守方 2=裁判/观战
			status = eBatStatus.eInit,
			cmds = {},
			report = nil,		-- 战报
		}
	end
	self.rate = rate
	self.tick = math.floor(100/rate)
	self.fmax = math.ceil(time*1000/(self.tick * 10))
	self.time = time
	-- 开启房间状态计时器, 一段时间后仍未所有人都准备完成, 则释放战场
	frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, svrFunc.systemTime()+gPvpFreeTime)
	gLog.i("room:init end, eWaitPrepare=", self.batId, self.status)

	return true
end

function room:isAllStatus(status)
	local all = true
	for k,v in pairs(self.info) do
		if v.camp == 0 or v.camp == 1 then
			if v.status < status then
				all = false
			end
		end
	end
	return all
end

-- 请求准备完成
function room:reqPrepare(uid)
	gLog.i("room:reqPrepare=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
	if not self.info[uid] then
		gLog.w("room:reqPrepare err=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NO_USER
	end
	if self.info[uid].status == eBatStatus.eFree then
		gLog.w("room:reqPrepare err=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_HAD_LEAVE
	end
	if self.isEnd or self.status >= eBatStatus.eSettle then
		gLog.w("room:reqPrepare err=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NOT_START_OR_END
	end
	if self.info[uid].status < eBatStatus.eWaitPrepare then
		self.info[uid].status = eBatStatus.eWaitPrepare
		if self:isAllStatus(eBatStatus.eWaitPrepare) then -- 所有人准备完成
			self.status = eBatStatus.eWaitLoad
			gLog.i("room:reqPrepare change status eWaitLoad=", self.batId, self.status)
			-- 开启房间状态计时器, 一段时间后仍未所有人都加载场景完成, 则直接开始跑帧
			frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, svrFunc.systemTime()+120)
		end
		-- 推送客户端
		frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
	end
	return true
end

-- 请求加载场景完成
function room:reqLoad(uid)
	gLog.i("room:reqLoad", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
	if not self.info[uid] then
		gLog.w("room:reqLoad err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NO_USER
	end
	if self.info[uid].status == eBatStatus.eFree then
		gLog.w("room:reqLoad err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_HAD_LEAVE
	end
	if self.isEnd or self.status >= eBatStatus.eSettle then
		gLog.w("room:reqLoad err=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NOT_START_OR_END
	end
	if self.info[uid].status < eBatStatus.eWaitLoad then
		self.info[uid].status = eBatStatus.eWaitLoad
		if self:isAllStatus(eBatStatus.eWaitLoad) then -- 所有人加载场景完成
			self.status = eBatStatus.eGame
			gLog.i("room:reqLoad change status eGame=", self.batId, self.status)
			-- 开始跑逻辑帧
			self:start()
		end
		-- 推送客户端
		frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
	end
	return true
end

-- 请求退出战场
function room:reqLeave(uid)
	gLog.i("room:reqLeave begin=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
	if not self.info[uid] then
		gLog.w("room:reqLeave err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NO_USER
	end
	--
	self.info[uid].status = eBatStatus.eFree
	-- 若所有人都已退出战场, 则战场结束
	local all = true
	for uid,v in pairs(self.info) do
		if v.camp == 0 or v.camp == 1 then
			if v.status ~= eBatStatus.eFree then
				all = false
				break
			end
		end
	end
	if all then
		self.isEnd = true
	end
	-- 推送客户端
	frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
	gLog.i("room:reqLeave end=", self.batId, self.status, uid, "all=", all)

	return true
end

-- 请求提交帧指令 cmd见.sPvpCmd
function room:reqCommitCmd(uid, cmd)
	---- 压测
	--if self.batId == "1999" then
	--	gLog.d("room:reqCommitCmd=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
	--end
	if not self.info[uid] then
		gLog.w("room:reqCommitCmd err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NO_USER
	end
	if self.status ~= eBatStatus.eGame then
		gLog.w("room:reqCommitCmd err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NOT_START_OR_END
	end
	cmd.uid = uid
	cmd.f = self.f
	self.info[uid].cmds[self.f] = cmd

	return true
end

-- 请求提交战报
function room:reqCommitReport(uid, report)
	gLog.d("room:reqCommitReport begin=", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
	if not self.info[uid] then
		gLog.w("room:reqCommitReport err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NO_USER
	end
	if not (self.status == eBatStatus.eGame or self.status == eBatStatus.eSettle) then
		gLog.w("room:reqCommitReport err", self.batId, self.status, uid, self.info[uid] and self.info[uid].status)
		return false, gErrDef.Err_ROOM_NOT_START_OR_END
	end
	self.info[uid].report = report
	-- 若所有人都已提交战报, 则战场执行结算
	local all = true
	for uid,v in pairs(self.info) do
		if v.camp == 0 or v.camp == 1  then
			if not v.report then
				all = false
			end
		end
	end
	if all then
		gLog.i("room:reqCommitReport free", self.batId, self.status)
		self:free()
	end

	return true
end

-- 开始跑逻辑帧
function room:start()
	gLog.i("room:start begin=", self.batId, self.status)
	--
	self.status = eBatStatus.eGame
	-- 所有人状态改为跑逻辑帧中
	for k,v in pairs(self.info) do
		if v.status < eBatStatus.eGame then
			v.status = eBatStatus.eGame
		end
	end
	-- 开启房间状态计时器, 一段时间后结束跑帧、结算战场
	frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, svrFunc.systemTime()+self.time)
	-- 跑逻辑帧
	-- skynet.fork(self.game, self) -- bug: 若直接这么调用战场一多, 有协程饿死(默认调度问题)
	self.msg = {f = nil, fs = {}}
	frameCenter.userMgr:game(self.tick, self.batId, self)
	gLog.i("room:start end=", self.batId, self.status)
end

-- 跑逻辑帧
--function room:game()
--	gLog.i("room:game begin=", self.batId, self.status)
--	local msg = self.msg
--	while(true) do
--		if self.f >= self.fmax or self.isEnd then
--			gLog.i("room:game over=", self.batId, self.status, self.f, self.fmax, self.isEnd)
--			break
--		end
--		-- 打包所有玩家帧, 并推送给所有玩家
--		msg.f = self.f
--		msg.batId = self.batId
--		for uid,v in pairs(self.info) do
--			msg.fs[uid] = v.cmds[msg.f] or nil --见.sPvpCmd
--		end
--		-- 推送客户端
--		frameCenter:notifyMsgBatch(self.users, "notifyPvpCmd", msg)
--		-- 帧数+1
--		self.f = self.f + 1
--		-- 睡眠
--		skynet.sleep(self.tick)
--	end
--	-- 设置游戏结束, 等待结算状态
--	self.status = eBatStatus.eSettle
--	for uid,v in pairs(self.info) do
--		v.status = eBatStatus.eSettle
--	end
--	-- 推送客户端
--	frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
--	-- 开启房间状态计时器, 一段时间后仍未收到所有人的战报, 则强制结算并释放房间
--	frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, svrFunc.systemTime()+20)
--	gLog.i("room:game end=", self.batId, self.status)
--end

-- 跑逻辑帧
function room:game()
	--gLog.d("room:game=", self.batId)
	if self.f >= self.fmax or self.isEnd then
		gLog.i("room:game over=", self.batId, self.status, self.f, self.fmax, self.isEnd)
		self:over()
		return true --跑帧结束
	end
	-- 打包所有玩家帧, 并推送给所有玩家
	self.msg.f = self.f
	self.msg.batId = self.batId
	for uid,v in pairs(self.info) do
		self.msg.fs[uid] = v.cmds[self.msg.f] or nil --见.sPvpCmd
	end
	-- 推送客户端
	frameCenter:notifyMsgBatch(self.users, "notifyPvpCmd", self.msg)
	-- 帧数+1
	self.f = self.f + 1
	---- 压测
	--if self.batId == "1999" then
	--	gLog.d("room:game 1999", table2string(self.msg))
	--end
end

-- 跑帧结束
function room:over()
	-- 设置游戏结束, 等待结算状态
	self.status = eBatStatus.eSettle
	for uid,v in pairs(self.info) do
		v.status = eBatStatus.eSettle
	end
	gLog.i("room:over=", self.batId, self.status)
	-- 推送客户端
	frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
	-- 开启房间状态计时器, 一段时间后仍未收到所有人的战报, 则强制结算并释放房间
	frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, svrFunc.systemTime()+20)
end

-- 结束并释放战场
function room:free()
	gLog.i("room:free begin=", self.batId, self.status)
	if self.status >= eBatStatus.eFree then
		gLog.i("room:free ignore=", self.batId, self.status)
		return
	end
	-- 删除计时器
	frameCenter.timerMgr:updateTimer(self.batId, gPvpTimerType.status, nil)
	--
	local status = self.status
	self.status = eBatStatus.eFree
	for uid,v in pairs(self.info) do
		v.status = eBatStatus.eFree
	end
	-- 结算战场, 发送战报或邮件等
	if status <= eBatStatus.eWaitLoad then
		-- 战场并未真正开始, 战场异常
	else
		-- 战场有真正开始, 战场正常结算
	end
	-- 推送客户端
	frameCenter:notifyMsgBatch(self.users, "notifyPvpInfo", {info = self:packInfo()})
	-- 释放room
	frameCenter.userMgr:delRoom(self.batId)
	gLog.i("room:free end=", self.batId, self.status)
end

-- 设置已结束
function room:setIsEnd(isEnd)
	gLog.i("room:setIsEnd", self.batId, self.status, isEnd)
	self.isEnd = isEnd
	if self.status < eBatStatus.eGame then
		self:free()
	end
end

function room:packInfo()
	return {status = self.status, info = self.info}
end

function room:getUsers()
	return self.users
end

function room:timerCallback()
	gLog.i("room:timerCallback", self.batId, self.status, self)
	if self.status <= eBatStatus.eWaitPrepare then
		self:setIsEnd(true)
	elseif self.status == eBatStatus.eWaitLoad then
		self:start()
	elseif self.status == eBatStatus.eGame then
		self:setIsEnd(true)
	elseif self.status == eBatStatus.eSettle then
		self:free()
	else
		gLog.i("room:timerCallback ignore", self.batId, self.status)
	end
end

return room