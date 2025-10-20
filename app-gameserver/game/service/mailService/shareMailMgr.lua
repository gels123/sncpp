--[[
	共享邮件(注:邮件数量需要做限制,否则可能导致mysql数据截断)
	简介：共享邮件, 在数据库中只存在一份。有新的共享邮件时，只有在线的玩家可以立即收到，而离线玩家在下次登录时可以读取到。同时对全服玩家发送邮件时，这样可以缓解服务器和数据库的压力。
--]]
local skynet = require("skynet")
local skynetQueue = require("skynet.queue")
local playerDataLib = require("playerDataLib")
local mailConf = require("mailConf")
local mailCenter = require("mailCenter"):shareInstance()
local shareMailMgr = class("shareMailMgr")

-- 构造
function shareMailMgr:ctor()
	self.module = "mailshare"	        -- 数据表名
	self.data = nil		                -- 数据
	self.midRef = {}					-- 邮件id关联
	self.sq = skynetQueue()				-- 串行队列
end

-- 初始化
function shareMailMgr:init()
	self.data = self:queryDB()
	if "table" ~= type(self.data) then
		self.data = self:defaultData()
		self:updateDB()
	end
	--gLog.dump(self.data, "shareMailMgr:init data=")
	if self.data.list then
		for _,v in ipairs(self.data.list) do
			self.midRef[v.mid] = v
		end
	end
	-- 更新过期计时器
	self:updateExpireTimer()
end

-- 默认数据
function shareMailMgr:defaultData()
	return {
		maxId = 0,							-- 自增id
		list = {},							-- 共享邮件列表
	}
end

-- 默认邮件列表单元
function shareMailMgr:defaultListCell(id, mid, castleLv, logoutTime, isNewUsr, expiretime)
	return {
		id = id,
		mid = mid, 								-- 共享邮件ID
		castleLv = castleLv or 0,				-- 玩家城堡等级限制, 默认0, 表示无限制
		logoutTime = logoutTime or 0,  			-- 玩家离线天数限制, 默认0, 表示无限制
		isNewUsr = isNewUsr,	    			-- 新账号是否可以收到
		expiretime = (expiretime or 0) <= 0 and 0 or (svrFunc.systemTime() + (mailConf.expiretime or 0)), -- 过期时间
	}
end

-- 查询数据库
function shareMailMgr:queryDB()
	assert(self.module, "shareMailMgr:queryDB error!")
	return playerDataLib:query(mailCenter.kid, self:getId(), self.module)
end

-- 更新数据库
function shareMailMgr:updateDB()
	assert(self.module and self.data, "shareMailMgr:updateDB error!")
	playerDataLib:sendUpdate(mailCenter.kid, self:getId(), self.module, self.data)
end

-- 获取数据ID
function shareMailMgr:getId()
	return mailCenter.kid * 10 + mailCenter.idx
end

-- 获取属性
function shareMailMgr:getAttr(k)
	if not k then
		return self.data
	else
		return self.data[k]
	end
end

-- 设置属性
function shareMailMgr:setAttr(k, v, save)
	if self.data[k] ~= v then
		self.data[k] = v
		if save then
			self:updateDB()
		end
	end
end

-- 排队
function shareMailMgr:queue(f)
	return self.sq(f)
end

-- 获取邮件
function shareMailMgr:getSharedMail(mid)
	if mid then
		return self.midRef[mid]
	end
end

--删除邮件
function shareMailMgr:delSharedMail(mid)
	gLog.i("shareMailMgr:delSharedMail", mid)
	if mid and self.midRef[mid] then
		self.midRef[mid] = nil
		for k,v in ipairs(self.data.list) do
			if v.mid == mid then
				table.remove(self.data.list, k)
				self:updateDB()
				return
			end
		end
	end
end

-- 创建共享邮件
function shareMailMgr:createMail(mid, castleLv, logoutTime, isNewUsr, expiretime)
	self.data.maxId = (self.data.maxId or 0) + 1
	local cell = self:defaultListCell(self.data.maxId, mid, castleLv, logoutTime, isNewUsr, expiretime)
	table.insert(self.data.list, cell)
	if #self.data.list > mailConf.shareMailLimit then
		local v = table.remove(self.data.list, 1)
		self.midRef[v.mid] = nil
	end
	self.midRef[mid] = cell
	self:updateDB()
    return true
end

-- 根据玩家上次读取的邮件ID, 导入新的共享邮件
function shareMailMgr:loadMail(lastId, castleLv, isNewUsr)
	if lastId >= self:getMaxID() then
		return
	end
	return self:queue(function()
		local ret, lastId_ = {}, lastId
		if lastId <= 0 then
			isNewUsr = true
		end
		if isNewUsr then
			for k,v in ipairs(self.data.list) do
				if v.id > lastId_ then
					lastId_ = v.id
				end
				if --[[v.isNewUsr and]] v.id > lastId and castleLv >= v.castleLv then
					table.insert(ret, v.mid)
				end
			end
		else
			for k,v in ipairs(self.data.list) do
				if v.id > lastId_ then
					lastId_ = v.id
				end
				if v.id > lastId and castleLv >= v.castleLv then
					table.insert(ret, v.mid)
				end
			end
		end
		return ret, lastId_
	end)
end

function shareMailMgr:getMaxID()
	return self.data.maxId or 0
end

-- 更新过期计时器
function shareMailMgr:updateExpireTimer()
	local time, bSave, lasttime, cell = svrFunc.systemTime(), false, nil, nil
	for k=#self.data.list,1,-1 do
		cell = self.data.list[k]
		if cell and cell.expiretime then
			if cell.expiretime > 0 then
				if cell.expiretime <= time then --清理过期数据
					bSave = true
					table.remove(self.data.list, k)
					self.midRef[cell.mid] = nil
					mailCenter.mailDataMgr:remove(cell.mid, nil, true)
				else
					if not lasttime or lasttime > cell.expiretime then
						lasttime = cell.expiretime
					end
				end
			end
		end
	end
	gLog.d("shareMailMgr:updateExpireTimer", bSave, lasttime)
	if bSave then
		self:updateDB()
	end
	mailCenter.timerMgr:updateTimer(-1, mailConf.timerType.shareExpire, lasttime)
end

return shareMailMgr