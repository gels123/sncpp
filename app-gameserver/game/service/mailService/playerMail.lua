--[[
	玩家邮件信息(注:邮件数量需要做限制,否则可能导致mysql数据截断)
]]
local skynet = require("skynet")
local svrFunc = require("svrFunc")
local mailConf = require("mailConf")
local playerDataLib = require("playerDataLib")
local mailCenter = require("mailCenter"):shareInstance()
local playerMail = class("playerMail")

-- 构造
function playerMail:ctor(uid)
	assert(uid and uid > 0)
	self.module = "mail"	        	-- 数据表名
	self.uid = uid						-- 玩家ID
	self.data = nil		                -- 数据

	self.online = false					-- 是否在线
	self.midRef = {}					-- 邮件集合关联
	self.coverRef = {}					-- 邮件集合封面关联

	for _,settype in pairs(mailConf.setTypes) do
		self.midRef[settype] = {}
		self.coverRef[settype] =
		{
			settype = settype,
			totalNum = 0,
			notViewNum = 0,
			hasExtraNum = 0,
		}
	end
end

-- 获取玩家id
function playerMail:getUid()
	return self.uid
end

-- 初始化
function playerMail:init()
	self.data = self:queryDB()
	if "table" ~= type(self.data) then
		self.data = self:defaultData()
		self:updateDB()
	end
	-- 维护关联
	for _,v in pairs(self.data.list) do
		for _,cell in pairs(v) do
			self:addRef(cell)
		end
	end
	-- 跨服邮件相关处理
	if self.data.curKid ~= mailCenter.kid then
		local maxId = mailCenter.shareMailMgr:getMaxID()
		gLog.i("playerMail:init migrate=", self.uid, self.data.curKid, self.data.curShareId, maxId)
		self:loadShareMail(1, false, self.data.curKid)
		self.data.curKid = mailCenter.kid
		self.data.curShareId = maxId
		self:updateDB()
	end
	gLog.i("playerMail:init ok, uid=", self.uid, self.data.curKid)
end

-- 默认数据
function playerMail:defaultData()
	return {
		curKid = mailCenter.kid, 			-- 当前KID
		curShareId = 0, 					-- 当前共享邮件ID
		list = {},							-- 邮件列表
	}
end

-- 默认邮件列表单元
function playerMail:defaultListCell(mid, mailtype, settype, cfgid, hasExtra, brief, expiretime)
	return {
		mid = mid, 					-- 邮件ID
		mailtype = mailtype,		-- 邮件类型
		settype = settype,			-- 邮件集合类型
		cfgid = cfgid,	    		-- 邮件配置ID
		hasExtra = hasExtra,		-- 是否有附件
		brief = brief or "",	    -- 简要标题数据
		expiretime = expiretime,	-- 过期时间
		isGetExtra = false,			-- 附件状态，默认为未领取
		isView = false,				-- 查阅状态，默认为未读
		isLock = false,				-- 锁定状态，默认为未锁定
		createTime = svrFunc.systemTime(),	-- 创建时间
	}
end

-- 查询数据库
function playerMail:queryDB()
	assert(self.uid and self.module, "playerMail:queryDB error!")
	return playerDataLib:query(mailCenter.kid, self.uid, self.module)
end

-- 更新数据库
function playerMail:updateDB()
	assert(self.uid and self.module and self.data, "playerMail:updateDB error!")
	playerDataLib:sendUpdate(mailCenter.kid, self.uid, self.module, self.data)
end

-- 获取属性
function playerMail:getAttr(k)
	if not k then
		return self.data
	else
		return self.data[k]
	end
end

-- 设置属性
function playerMail:setAttr(k, v, save)
	if self.data[k] ~= v then
		self.data[k] = v
		if save then
			self:updateDB()
		end
	end
end

-- 添加新邮件
function playerMail:addNewMail(mid, mailtype, settype, cfgid, hasExtra, brief, expiretime, isshared)
	gLog.i("playerMail:addNewMail", self.uid, mid, mailtype, settype, cfgid, hasExtra, expiretime, isshared)
	-- 检查邮件数据
	local mailData = mailCenter.mailDataMgr:query(mid)
	if not mailData then
		gLog.e("playerMail:addNewMail error1", self.uid, mid, mailtype, settype, cfgid, hasExtra, expiretime, isshared)
		return false, gErrDef.Err_MAIL_NO_DATA
	end
	local list = self.data.list
	-- 添加到邮件列表
	local cell = self:defaultListCell(mid, mailtype, settype, cfgid, hasExtra, brief, expiretime)
	if not list[settype] then
		list[settype] = {}
	end
	table.insert(list[settype], 1, cell)
	-- 若邮件数量超上限, 删除一封邮件, 优先级1: 早期的没附件的或已领取附件的, 优先级2: 最早的有附件的
	local len = #list[settype]
	if len > mailConf.setTypesLimit[settype] then
		local rmcell = list[settype][len]
		if rmcell.hasExtra and not rmcell.isGetExtra then
			for l = len-1, 2, -1 do
				if not list[settype][l].hasExtra or list[settype][l].isGetExtra then
					rmcell = list[settype][l]
					break
				end
			end
		end
		self:removeMail(rmcell.mid, true, rmcell)
	end
	-- 维护关联
	self:addRef(cell)
	-- 共享邮件
	if isshared then
		local v = mailCenter.shareMailMgr:getSharedMail(mid)
		if v and v.id > (self:getAttr("curShareId") or 0) then
			self:setAttr("curShareId", v.id)
		end
	end
	-- 更新数据库
	self:updateDB()
	-- 推送客户端
	if self.online then
		require("agentLib"):notifyMsg(mailCenter.kid, self.uid, "newMail", {settype = settype, cover = self.coverRef[settype], cell = cell,})
	end
	return true
end

-- 删除邮件 isAuto=是否自动删除过期邮件
function playerMail:removeMail(mid, isAuto, cell)
	-- 检查是否存在
	if not cell then
		cell = self:getListCell(mid)
	end
	if not cell then
		if not isAuto then
			gLog.w("playerMail:removeMail error1", self.uid, mid, self:getAttr("cfgid"))
		end
		return false
	end
	-- 有附件没领取的不能删除
	if not isAuto and cell.hasExtra and not cell.isGetExtra then
		gLog.w("playerMail:removeMail error2", self.uid, mid, self:getAttr("cfgid"))
		return false
	end
	-- 删除邮件
	local settype, cfgid = cell.settype, self:getAttr("cfgid")
	gLog.i("playerMail:removeMail", self.uid, "mid=", mid, settype, cfgid, isAuto)
	local bSave = false
	for k,v in pairs(self.data.list[settype]) do
		if v.mid == mid then
			bSave = true
			table.remove(self.data.list[settype], k)
			break
		end
	end
	-- 维护关联
	self:removeRef(cell)
	-- 更新数据库
	if bSave then
		self:updateDB()
	else
		gLog.w("playerMail:removeMail fail", self.uid, mid, settype, cfgid, isAuto)
	end
	-- 删除邮件数据
	skynet.fork(function()
		mailCenter.mailDataMgr:remove(mid, self.uid, false)
	end)
	-- 推送客户端
	if self.online then
		require("agentLib"):notifyMsg(mailCenter.kid, self.uid, "removeMail", {settype = settype, mids = {mid}, cover = self.coverRef[settype],})
	end
	return true
end

--
function playerMail:getListCell(mid)
	for _,v in pairs(self.midRef) do
		if v[mid] then
			return v[mid]
		end
	end
end

-- 维护关联
function playerMail:addRef(cell)
	local mid, settype = cell.mid, cell.settype
	if self.midRef[settype] and self.coverRef[settype] and not self.midRef[settype][mid] then
		self.midRef[settype][mid] = cell
		self.coverRef[settype].totalNum = self.coverRef[settype].totalNum + 1
		if not cell.isView then
			self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum + 1
		end
		if cell.hasExtra and not cell.isGetExtra then
			self.coverRef[settype].hasExtraNum = self.coverRef[settype].hasExtraNum + 1
		end
	else
		gLog.e("playerMail:addRef error", mid, settype, self.midRef[settype][mid])
	end
end

function playerMail:removeRef(cell)
	local mid, settype = cell.mid, cell.settype
	if self.midRef[settype] and self.coverRef[settype] and self.midRef[settype][mid] then
		self.midRef[settype][mid] = nil
		self.coverRef[settype].totalNum = self.coverRef[settype].totalNum - 1
		if not cell.isView then
			self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum - 1
		end
		if cell.hasExtra and not cell.isGetExtra then
			self.coverRef[settype].hasExtraNum = self.coverRef[settype].hasExtraNum - 1
		end
	else
		gLog.e("playerMail:removeRef error", mid, settype, self.midRef[settype][mid])
	end
end

-- 登陆
function playerMail:checkin(castleLv, isNewUsr)
	if self.online then
		gLog.i("playerMail:checkin ignore uid=", self.uid)
		return
	end
	gLog.i("playerMail:checkin uid=", self.uid)
	-- 设置在线
	self.online = true
	-- 加载共享邮件
	self:loadShareMail(castleLv, isNewUsr)
	-- 更新过期计时器
	self:updateExpireTimer()
	--gLog.dump(self, "playerMail:checkin self=")
end

-- 登出
function playerMail:afk()
	gLog.i("playerMail:afk uid=", self.uid)
	-- 设置离线
	self.online = false
	-- 移除过期计时器
	mailCenter.timerMgr:updateTimer(self.uid, mailConf.timerType.playerExpire, nil)
end

-- 导入新的共享邮件
function playerMail:loadShareMail(castleLv, isNewUsr, sKid)
	local curShareId = self:getAttr("curShareId") or 0
	local bSave, ret, lastMidNew = false, nil, nil
	if sKid and sKid > 0 then
		local ok
		ok, ret, lastMidNew = pcall(function()
			local v = require("initDBConf"):getKingdomConf(sKid)
			if v then
				local r = string.trim(io.popen(string.format("echo ' ' | telnet %s %d", v.web ~= "127.0.0.1" and v.web ~= "localhost" and v.web or v.ip, v.port)):read("*all") or "")
				if string.find(r, "Connected") then
					return require("mailLib"):call(sKid, self.uid, "loadShareMail", self.uid, curShareId, castleLv, isNewUsr)
				end
			end
		end)
		if not ok or not ret then
			return
		end
	else
		ret, lastMidNew = mailCenter.shareMailMgr:loadMail(curShareId, castleLv or 1, isNewUsr)
		if not ret then
			return
		end
		gLog.i("playerMail:loadShareMail uid=", self.uid, "curShareId=", curShareId, "lastMidNew=", lastMidNew, "maxId=", mailCenter.shareMailMgr:getMaxID())
		if lastMidNew > curShareId then
			bSave = true
			self:setAttr("curShareId", lastMidNew)
		end
	end
	if next(ret) then
		for _,mid in ipairs(ret) do
			--if mailCenter.shareMailMgr:getSharedMail(mid) then
				local mailData = mailCenter.mailDataMgr:query(mid)
				if mailData then
					xpcall(function()
						local ok, code = self:addNewMail(mid, mailData:getAttr("mailtype"), mailData:getAttr("settype"), mailData:getAttr("cfgid"), mailData:hasExtra(), mailData:getAttr("content").brief, mailData:getAttr("expiretime"), true)
						if not ok then
							gLog.e("mailCenter:loadShareMail error, uid=", self.uid, "mid=", mid, code)
						else
							gLog.i("mailCenter:loadShareMail ok, uid=", self.uid, "mid=", mid)
						end
					end, svrFunc.exception)
				end
			--end
		end
		bSave = true
	end
	-- 更新数据库
	if bSave then
		self:updateDB()
	end
	return bSave
end

-- 更新过期计时器
function playerMail:updateExpireTimer()
	local time, bSave, lasttime, cell = svrFunc.systemTime(), false, 0, nil
	for settype,v in pairs(self.data.list) do
		for k=#v,1,-1 do
			cell = v[k]
			if cell and cell.expiretime and cell.expiretime > 0 then
				if cell.expiretime <= time then --清理过期数据
					bSave = true
					self:removeMail(cell.mid, true, cell)
				else
					if not time or cell.expiretime < lasttime then
						lasttime = cell.expiretime
					end
				end
			end
		end
	end
	gLog.d("playerMail:updateExpireTimer", bSave, lasttime)
	if bSave then
		self:updateDB()
	end
	mailCenter.timerMgr:updateTimer(self.uid, mailConf.timerType.playerExpire, lasttime)
end

-- 请求邮件封面数据
function playerMail:reqCovers()
	return self.coverRef
end

-- 请求邮件简要信息
function playerMail:reqMailBrief(settype, begin, over)
	if self.data.list[settype] then
		local ret, autoViewMids, cell = {}, {}, nil
		for k=begin, over, 1 do
			cell = self.data.list[settype][k]
			if not cell then
				break
			end
			-- 一些邮件获取简要信息时自动全部已读
			if mailConf.viewMailWhenReqBrief[settype] and not cell.isView then
				cell.isView = true
				self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum - 1
				table.insert(autoViewMids, cell.mid)
			end
			table.insert(ret, cell)
		end
		if not next(ret) then
			return nil, gErrDef.Err_MAIL_NO_MORE
		end
		return ret, self.coverRef[settype], autoViewMids
	else
		return nil, gErrDef.Err_ILLEGAL_PARAMS
	end
end

-- 请求邮件详细信息/查看分享邮件
function playerMail:reqMailDetail(settype, mid, flag)
	gLog.d("reqMailDetail", self.uid, settype, mid, flag)
	local cell = self.midRef[settype] and self.midRef[settype][mid]
	if cell then
		if not cell.isView then
			cell.isView = true
			self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum - 1
			self:updateDB()
		end
		local mailData = mailCenter.mailDataMgr:query(mid)
		if mailData then
			if flag then
				return mailData:getAttr("content"), self.coverRef[settype], cell.brief, cell.cfgid
			else
				return mailData:getAttr("content"), self.coverRef[settype]
			end
		else -- 异常处理
			gLog.e("playerMail:reqMailDetail error", self.uid, settype, mid, cell.cfgid)
			self:removeMail(mid, true, cell)
		end
	elseif flag then
		local mailData = mailCenter.mailDataMgr:query(mid)
		if mailData then
			if flag then
				return mailData:getAttr("content"), self.coverRef[settype], mailData:getAttr("content").brief, mailData:getAttr("cfgid")
			else
				return mailData:getAttr("content"), self.coverRef[settype]
			end
		end
	end
	return nil, gErrDef.Err_MAIL_NOT_EXSIT
end

-- 请求删除邮件
function playerMail:reqDelMail(settype, mids)
	local ret = {}
	for _,mid in pairs(mids) do
		if self.midRef[settype] and self.midRef[settype][mid] then
			if self:removeMail(mid, false, self.midRef[settype][mid]) then
				table.insert(ret, mid)
			end
		end
	end
	return ret, self.coverRef[settype]
end

-- 请求一键删除邮件
function playerMail:reqDelMailOneKey(settype)
	local ret = {}
	if self.midRef[settype] then
		for mid,cell in pairs(self.midRef[settype]) do
			if self:removeMail(mid, false, cell) then
				table.insert(ret, mid)
			end
		end
	end
	return ret, self.coverRef[settype]
end

-- 请求领取邮件附件
function playerMail:reqGetMailExtra(settype, mid)
	local cell = self.midRef[settype] and self.midRef[settype][mid]
	if cell and cell.hasExtra and not cell.isGetExtra then
		-- 获取附件
		local extra = {}
		local mailData = mailCenter.mailDataMgr:query(mid)
		if mailData then
			local content = mailData:getAttr("content")
			extra = content and content.extra
		else -- 异常处理
			gLog.e("playerMail:reqGetMailExtra error", self.uid, settype, mid, cell.cfgid)
			self:removeMail(mid, true, cell)
		end
		-- 是否背包已满
		if next(extra) and false then
			return nil, gErrDef.Err_MAIL_FULL_PACKAGE
		end
		-- 设置已读, 领取附件
		if not cell.isView then
			cell.isView = true
			self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum - 1
		end
		cell.isGetExtra = true
		self.coverRef[settype].hasExtraNum = self.coverRef[settype].hasExtraNum - 1
		-- 更新数据库
		self:updateDB()
		return extra, self.coverRef[settype]
	else
		gLog.w("playerMail:reqGetMailExtra error", self.uid, settype, mid)
		return nil, gErrDef.Err_MAIL_NOT_EXSIT
	end
end

-- 请求一键领取邮件附件
function playerMail:reqGetMailExtraOneKey(settypes)
	local mids, extras, covers, errcells = {}, {}, {}, {}
	for _,settype in pairs(settypes) do
		if self.midRef[settype] then
			for mid,cell in pairs(self.midRef[settype]) do
				if cell.hasExtra and not cell.isGetExtra then
					local mailData = mailCenter.mailDataMgr:query(mid)
					if mailData then
						local content = mailData:getAttr("content")
						if content and content.extra and next(content.extra) then
							extras = svrFunc.mergeReward(extras, content.extra)
						end
					end
				else
					table.insert(errcells, cell)
				end
			end
		end
	end
	-- 异常处理
	if next(errcells) then
		gLog.e("playerMail:reqGetMailExtraOneKey error", self.uid, "errcells=", table2string(errcells))
		for _,cell in pairs(errcells) do
			self:removeMail(cell.mid, true, cell)
		end
	end
	-- 是否背包已满
	if next(extra) and false then
		return nil, gErrDef.Err_MAIL_FULL_PACKAGE
	end
	local bSave, flag = false, false
	for _,settype in pairs(settypes) do
		if self.midRef[settype] then
			for mid,cell in pairs(self.midRef[settype]) do
				flag = false
				if not cell.isView then
					cell.isView = true
					self.coverRef[settype].notViewNum = self.coverRef[settype].notViewNum - 1
					flag = true
				end
				if cell.hasExtra then
					if not cell.isGetExtra then
						cell.isGetExtra = true
						self.coverRef[settype].hasExtraNum = self.coverRef[settype].hasExtraNum - 1
						flag = true
					end
				end
				if flag then
					table.insert(mids, mid)
					bSave = true
				end
			end
			table.insert(covers, self.coverRef[settype])
		end
	end
	if bSave then
		self:updateDB()
	end
	return mids, extras, covers
end

-- 请求收藏邮件
function playerMail:reCollectMail(settype, mid)
	local cell = self.midRef[settype] and self.midRef[settype][mid]
	if not cell then
		return nil, gErrDef.Err_MAIL_NOT_EXSIT
	end
	if cell.isLock then
		return nil, gErrDef.Err_ILLEGAL_PARAMS
	end
	-- 有附件没领取的不能收藏
	if cell.hasExtra and not cell.isGetExtra then
		return nil, gErrDef.Err_MAIL_COLLECT_EXTRA
	end
	-- 收藏上限判断
	local settype2 = mailConf.setTypes.setCollect
	if #self.data.list[settype2] >= mailConf.setTypesLimit[settype2] then
		return nil, gErrDef.Err_MAIL_COUNT_LIMIT
	end
	self:removeRef(cell)
	cell.isLock = true
	self:addRef(cell)
	self:updateDB()
	return mid, {self.coverRef[settype], self.coverRef[settype2]}
end

return playerMail
