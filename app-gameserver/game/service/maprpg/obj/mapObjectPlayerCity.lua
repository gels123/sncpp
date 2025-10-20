--[[
	地图玩家主城
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectPlayerCity = class("mapObjectPlayerCity", mapObjectCell)

-- override
function mapObjectPlayerCity.get_db_fields()
    local db_fields = mapObjectPlayerCity.super.get_db_fields()
    table.merge(db_fields, {
    	__table__ = "playercityobject",
		__dirtytime__ = 5,
    	playerid = models.NumberField(),
		castlelv = models.NumberField(),    --城堡等级
		offlinetime = models.NumberField(), --离线时间
		scoutInfo = models.TableField(), 	--被侦查信息
		skin = models.NumberField(), 		--皮肤
		skintime = models.NumberField(), 	--皮肤时间
		hp = models.NumberField(), 			--城防值
		recoverTime = models.NumberField(), --下次恢复时间
		recoverEndTime = models.NumberField(), --恢复截止时间
		ownUid = models.NumberField(),  	--归属玩家(奴役者)
		ownTime = models.NumberField(),  	--归属玩家(奴役截止时间)
		beSlaveCastleLv = models.NumberField(),--成为奴隶时的城堡等级
		beSlaveCageLv = models.NumberField(),--成为奴隶时的对方牢笼等级
        landshieldover = models.NumberField(),  --领地盾免战截止时间
        slaveNum = models.NumberField(),  	--拥有的俘虏数量
		burntime = models.NumberField(),  	--燃烧截止时间
    })
    return db_fields
end

function mapObjectPlayerCity:ctor(record)
	self.super.ctor(self, record)
end

--初始化
function mapObjectPlayerCity:init(params)
	gLog.d("mapObjectPlayerCity:init", params)
	self.super.init(self, params)
	assert(params.playerid)
end

function mapObjectPlayerCity:get_playerid()
	return self._record:get_field("playerid")
end

function mapObjectPlayerCity:set_playerid(playerid)
	self._record:set_field("playerid", playerid)
end

--能否删除
function mapObjectPlayerCity:canRemove(bForce)
	return false
end

function mapObjectPlayerCity:pack_message_data_detail()
	local msg = self.super.pack_message_data_detail(self)
	local mapPlayer = mapCenter.mapPlayerMgr:get_player(self:get_playerid())
	msg.score = mapPlayer and mapPlayer:get_score()
	msg.build = mapPlayer and mapPlayer:get_build()
	return msg
end

--获取需要继承的属性（迁城）
function mapObjectPlayerCity:pack_inherited_attr_data()
	return self:get_fields({"skin", "skintime", "ownUid", "ownTime", "beSlaveCastleLv", "beSlaveCageLv", "slaveNum"})
end

return mapObjectPlayerCity