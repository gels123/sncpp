--[[
	邮件数据单元
--]]
local skynet = require("skynet")
local playerDataLib = require("playerDataLib")
local mailCenter = require("mailCenter"):shareInstance()
local mailData = class("mailData")

-- 构造
function mailData:ctor(mid, data)
	assert(mid and mid > 0)
	self.module = "maildata"	        -- 数据表名
	self.mid = mid		            	-- id
	self.data = data		            -- 数据
end

-- 获取邮件id
function mailData:getMid()
	return self.mid
end

-- 初始化
function mailData:init()
	self.data = self:queryDB()
	if type(self.data) == "table" then
		return true
	end
end

-- 查询数据库
function mailData:queryDB()
	assert(self.module, "mailData:queryDB error!")
	return playerDataLib:query(mailCenter.kid, self.mid, self.module, true)
end

-- 更新数据库
function mailData:updateDB()
	assert(self.module and self.data, "mailData:updateDB error!")
	playerDataLib:sendUpdate(mailCenter.kid, self.mid, self.module, self.data, true)
end

-- 删除
function mailData:remove(uid, force)
	gLog.d("mailData:remove mid=", self:getAttr("mid"), self:getAttr("mailtype"), self:getAttr("count"), "uid=", uid, force)
	if not force and self:getAttr("isshared") then
		return false
	end
	if force then
		-- 删除邮件
		playerDataLib:sendDelete(mailCenter.kid, self.mid, self.module, nil)
		return true
	else
		local receivers = self:getAttr("receivers") or {}
		receivers[uid] = nil
		if not next(receivers) then
			-- 删除邮件
			playerDataLib:sendDelete(mailCenter.kid, self.mid, self.module, nil)
			return true
		else
			self:updateDB()
			return false
		end
	end
end

-- 获取属性
function mailData:getAttr(k)
	if not k then
		return self.data
	else
		return self.data[k]
	end
end

-- 设置属性
function mailData:setAttr(k, v, save)
	if self.data[k] ~= v then
		self.data[k] = v
		if save then
			self:updateDB()
		end
	end
end

-- 是否有附件
function mailData:hasExtra()
	if self.data.content and self.data.content.extra and next(self.data.content.extra) then
		return true
	end
	return false
end

return mailData