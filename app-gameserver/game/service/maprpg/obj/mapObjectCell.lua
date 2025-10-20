--[[
	地图对象单元基类
--]]
local skynet = require "skynet"
local mapUtils = require "mapUtils"
local queueUtils = require "queueUtils"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = class("mapObjectCell")

-- override
function mapObjectCell.get_db_fields()
    local db_fields = {
    	__table__ = "mapobject",
		__dirtytime__ = 30,
        objectid = models.NumberField(true),
        type = models.NumberField(),
	    subtype = models.NumberField(),
	    x = models.NumberField(),
	    y = models.NumberField(),
		updatetime = models.NumberField(),
    }
    return db_fields
end

-- 获取DB表
function mapObjectCell.get_db_table(self)
    if not self.db_table then
        local db_fields = self.get_db_fields()
        assert(db_fields)
        self.db_table = models.Model(db_fields)
    end
    return self.db_table
end

function mapObjectCell:ctor(record)
	assert(record)
	self._record = record
	self._ispack = nil
	self._pack = nil
end

--初始化
function mapObjectCell:init(params)
	-- gLog.dump(params, "queueCell:init params=", 10)
	assert(params.type and params.x and params.x >=0 and params.y and params.y >= 0)
    for k,v in pairs(params) do
        if self._record:is_field(k) then
            self._record:set_field(k, v)
        end
    end
end

function mapObjectCell:getMapType()
	return self._record:get_field("type") or 0
end

function mapObjectCell:getSubMapType()
	return self._record:get_field("subtype") or 0
end

function mapObjectCell:set_field(k, v, nodirty)
	self._record:set_field(k, v, nodirty)
	self._ispack = true
end

function mapObjectCell:get_field(k)
	return self._record:get_field(k)
end

function mapObjectCell:get_fields(colNames)
    if not colNames then
        return self._record:get_fields()
    else
        local ret = {}
        for _,k in pairs(colNames) do
            ret[k] = self._record:get_field(k)
        end
        return ret
    end
end

--是否不存库
function mapObjectCell:is_nosave()
	return false
end

--异步保存
function mapObjectCell:asyn_save()
	if not self:is_nosave() then
		self._record:asyn_save()
	end
end

--异步删除
function mapObjectCell:asyn_delete()
	if not self:is_nosave() then
		self._record:asyn_delete()
	end
end

function mapObjectCell:get_level()
	return self:get_field("level") or 0
end

function mapObjectCell:get_objectid()
	return self._record:get_field("objectid")
end

function mapObjectCell:set_pack(ispack)
	self._ispack = ispack
end

function mapObjectCell:get_obj_size()
	return mapUtils.get_obj_size(self:getMapType(), self:getSubMapType(), self:get_objectid())
end

--清除数据
function mapObjectCell:clear_data()
	assert()
end

function mapObjectCell:get_position()
	return self._record:get_field("x"), self._record:get_field("y")
end

function mapObjectCell:set_position(x, y)
	self._record:set_field("x", x)
	self._record:set_field("y", y)
end

function mapObjectCell:get_range()
	local type, subtype = self._record:get_field("type"), self._record:get_field("subtype")
	local x, y = self:get_position()
	x, y = mapUtils.get_fix_xy(x, y, type, subtype, self:get_objectid())
	local w, h = self:get_obj_size()
	return x, y, w, h, type
end

--能否删除
function mapObjectCell:canRemove(bForce)
	if not bForce and self:get_field("cantRemove") then
		return false
	end
	return true
end

--打包消息数据(简要信息)
function mapObjectCell:pack_message_data()
	if not self._pack or self._ispack then
		self._ispack = nil
		local ret = {
			objid = self:get_objectid(),
			type = self:getMapType(),
			subtype = self:getSubMapType(),
			x = self._record:get_field("x"),
			y = self._record:get_field("y"),
			level = self._record:get_field("level"),
			status = self._record:get_field("status"),
			statusStartTime = self._record:get_field("statusStartTime"),
			statusEndTime = self._record:get_field("statusEndTime"),
			hp = self._record:get_field("hp"),
			ownUid = self._record:get_field("ownUid"),
			ownAid = self._record:get_field("ownAid"),
			uid = self._record:get_field("uid"),
		}
		if ret.type == mapConf.object_type.playercity then
			-- 玩家城堡
			ret.uid = self._record:get_field("playerid") or 0
			ret.wallst = self._record:get_field("recoverTime") or 0
			ret.wallet = self._record:get_field("recoverEndTime") or 0
			if ret.uid and ret.uid > 0 then
				local mapPlayer = mapCenter.mapPlayerMgr:get_player(ret.uid)
				if mapPlayer then
					ret.name = mapPlayer:get_name()
					ret.level = mapPlayer:get_level()
					ret.castlelv = mapPlayer:get_castle_level()
					ret.head = mapPlayer:get_head()
					ret.skin = mapPlayer:get_skin()
					ret.skintime = mapPlayer:get_skintime()
					ret.border = mapPlayer:get_border()
					ret.language = mapPlayer:get_language()
					ret.aid = mapPlayer:get_guild_id()
					ret.abbr = mapPlayer:get_guild_short()
					ret.aname = mapPlayer:get_guild_name()
					ret.shieldover = mapPlayer:get_shieldover()
					ret.walllv = mapPlayer:get_walllv()
					ret.banner = mapPlayer:get_guild_banner()
					if ret.hp <= 0 then
						ret.hp = mapUtils:getPlayerCitydurability(ret.walllv)
						self._record:set_field("hp", ret.hp)
						self._record:asyn_save()
					end
					if ret.wallst > 0 then
						ret.wallst = ret.wallst - queueUtils:getHpRecoverTime(ret.type,ret.walllv)					
					elseif ret.wallst < 0 then
						ret.wallst = 0
					end
				elseif not mapCenter.initOverOk then
					self._ispack = true --服务器还没启动好, 打包得到的数据不全
				else
					gLog.e("mapObjectCell:pack_message_data error1", ret.objid, ret.uid)
				end
			elseif ret.uid then
				ret.aid = 0
			end
			ret.landshieldover = self._record:get_field("landshieldover") or 0
			ret.slaveNum = self._record:get_field("slaveNum") or 0
			if ret.ownUid and ret.ownUid > 0 then
				local mapPlayer = mapCenter.mapPlayerMgr:get_player(ret.ownUid)
				if mapPlayer then
					ret.ownAid = mapPlayer:get_guild_id()
					ret.ownAbbr = mapPlayer:get_guild_short()
					ret.ownBanner = mapPlayer:get_guild_banner()
				elseif not mapCenter.initOverOk then
					self._ispack = true  --服务器还没启动好, 打包得到的数据不全
				else
					gLog.e("mapObjectCell:pack_message_data error2", ret.objid, ret.ownUid)
				end
				ret.ownTime = self._record:get_field("ownTime") or 0
				ret.beSlaveCastleLv = self._record:get_field("beSlaveCastleLv") or 0
				ret.beSlaveCageLv = self._record:get_field("beSlaveCageLv") or 0
			else
				ret.ownUid = 0
				ret.ownAid = 0
				ret.ownAbbr = nil
				ret.ownBanner = nil
				ret.ownTime = 0
			end
			ret.burntime = self._record:get_field("burntime") or 0
		elseif ret.type == mapConf.object_type.buildmine or ret.type == mapConf.object_type.fortress then
			-- 建筑矿、碉堡
			ret.defenderCdTime = self._record:get_field("defenderCdTime")
			ret.groupId = self._record:get_field("groupId")
			ret.ownTime = self._record:get_field("ownTime") or 0
			ret.cumuValue = self._record:get_field("cumuValue")
			ret.shieldover = self._record:get_field("shieldover") or 0
			if ret.ownUid and ret.ownUid > 0 then
				local mapPlayer = mapCenter.mapPlayerMgr:get_player(ret.ownUid)
				if mapPlayer then
					ret.ownAid = mapPlayer:get_guild_id()
					ret.ownAbbr = mapPlayer:get_guild_short()
					ret.ownBanner = mapPlayer:get_guild_banner()
				elseif not mapCenter.initOverOk then
					self._ispack = true  --服务器还没启动好, 打包得到的数据不全
				else
					gLog.e("mapObjectCell:pack_message_data error3", ret.objid, ret.ownUid)
				end
			else
				ret.ownUid = 0
				ret.ownAid = 0
			end
			if ret.uid and ret.uid > 0 then
				local mapPlayer = mapCenter.mapPlayerMgr:get_player(ret.uid)
				if mapPlayer then
					ret.aid = mapPlayer:get_guild_id()
					ret.abbr = mapPlayer:get_guild_short()
					ret.banner = mapPlayer:get_guild_banner()
				elseif not mapCenter.initOverOk then
					self._ispack = true  --服务器还没启动好, 打包得到的数据不全
				else
					gLog.e("mapObjectCell:pack_message_data error4", ret.objid, ret.uid)
				end
			elseif ret.uid then
				ret.aid = 0
			end
		elseif mapConf.terr_object_type[ret.type] then
			-- 领地建筑
			ret.isAct = self._record:get_field("isAct")
			ret.buildType = self._record:get_field("buildType")
			ret.buildFlag = self._record:get_field("buildFlag")
			ret.buildTime = self._record:get_field("buildTime")
			ret.annouceTime = self._record:get_field("annouceTime")
			ret.defenderCdTime = self._record:get_field("defenderCdTime")
			ret.shieldover = self._record:get_field("shieldover")
			ret.maxhp = self._record:get_field("maxhp") or 0
			ret.zoneid = mapCenter.mapMaskMgr:get_subzone(ret.x, ret.y)
			if ret.ownAid and ret.ownAid > 0 then
				local aInfo = require("guildinterface").call_get_guildinfo(ret.ownAid, {"name", "shortname", "banner"})
				ret.ownAbbr = aInfo and aInfo.shortname or ""
				ret.ownBanner = aInfo and aInfo.banner or 0
				ret.ownName = aInfo and aInfo.name or ""
				if not aInfo then
					if not mapCenter.initOverOk then
						self._ispack = true  --服务器还没启动好, 打包得到的数据不全
					else
						gLog.e("mapObjectCell:pack_message_data error5", ret.objid, ret.ownAid)
					end
				end
			end
			if ret.uid and ret.uid > 0 then
				local mapPlayer = mapCenter.mapPlayerMgr:get_player(ret.uid)
				if mapPlayer then
					ret.aid = mapPlayer:get_guild_id()
					ret.abbr = mapPlayer:get_guild_short()
					ret.banner = mapPlayer:get_guild_banner()
				elseif not mapCenter.initOverOk then
					self._ispack = true  --服务器还没启动好, 打包得到的数据不全
				else
					gLog.e("mapObjectCell:pack_message_data error6", ret.objid, ret.uid)
				end
			elseif ret.uid then
				ret.aid = 0
			end
		elseif ret.type == mapConf.object_type.monster or ret.type == mapConf.object_type.chest then
			ret.taskID = self._record:get_field("taskID")
		end
		self._pack = ret
	end
	mapCenter.mapTimerMgr:doUpdate(self._pack.objid, "pack", svrFunc.systemTime()+3600)
	return self._pack
end

--打包消息数据(详细信息)
function mapObjectCell:pack_message_data_detail()
	local ret = {
		type = self:getMapType(),
	}
	if mapConf.terr_object_type[ret.type] then -- 领地建筑
		-- 拥有者信息
		local ownAid = self._record:get_field("ownAid")
		if ownAid and ownAid > 0 then
			local aInfo = require("guildinterface").call_get_guildinfo(ownAid, {"name",})
			ret.ownAname = aInfo and aInfo.name or ""
		end
		-- 占领者信息
		local uid = self._record:get_field("uid")
		if uid and uid > 0 then
			ret.uid = uid
			local mapPlayer = mapCenter.mapPlayerMgr:get_player(uid)
			ret.name = mapPlayer and mapPlayer:get_name() or ""
			ret.head = mapPlayer and mapPlayer:get_head() or 1
			ret.aid = mapPlayer and mapPlayer:get_guild_id() or 0
			ret.abbr = mapPlayer and mapPlayer:get_guild_short() or ""
			ret.aname = mapPlayer and mapPlayer:get_guild_name() or ""
		end
		ret.defenderNum = self._record:get_field("defenderNum") or 0
		return ret
	end
	return ret
end

--清除打包数据, 释放内存
function mapObjectCell:clean_pack()
	self._ispack = nil
	self._pack = nil
end

return mapObjectCell