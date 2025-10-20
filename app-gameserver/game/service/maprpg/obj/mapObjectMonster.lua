--[[
	地图怪物
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectMonster = class("mapObjectMonster", mapObjectCell)

-- override
function mapObjectMonster.get_db_fields()
    local db_fields = mapObjectMonster.super.get_db_fields()
    table.merge(db_fields, {
    	__table__ = "mapobjectmonster",
    	level = models.NumberField(), 		--怪物等级
   		hp = models.NumberField(),  		--怪物剩余量
   		ownUid = models.NumberField(),  	--怪物归属玩家
   		deadTime = models.NumberField(),    --怪物存活截止时间
		taskID = models.NumberField(),  	--雷达任务ID
    })
    return db_fields
end

--初始化
function mapObjectMonster:init(params)
	assert(params.subtype and params.subtype > 0)
	assert(params.level and params.level > 0)
	assert(params.hp and params.hp > 0)

	self.super.init(self, params)
end

--是否不存库
function mapObjectMonster:is_nosave()
	if self:get_field("cantRemove") or ((self:get_field("ownUid") or 0) > 0 and (self:get_field("deadTime") or 0) > svrFunc.systemTime()) then
		--被行军的、归属于玩家的, 需要存库
		self._record:set_nosave(false)
		return false
	end
	--由存库变成不存库, 需要删一下数据
	if self._record:is_nosave() == false then
		self._record:asyn_delete(nil, true)
	end
	self._record:set_nosave(true)
	return true
end

function mapObjectMonster:get_level()
	return self:get_field("level") or 0
end

function mapObjectMonster:get_hp()
	return self._record:get_field("hp") or 0
end

function mapObjectMonster:set_hp(hp)
	self._record:set_field("hp", hp)
end

function mapObjectMonster:alter_hp(v)
    local old = self:get_hp()
    local new = old - v
    if new < 0 then
        new = 0
    end
    self:set_hp(new)
end

function mapObjectMonster:get_config()
	local subtype, level = self:getSubMapType(), self:get_level()
	return get_static_config().monster_lv[subtype][level]
end

--打包消息数据(详细信息)
function mapObjectMonster:pack_message_data_detail()
	local ret = self.super.pack_message_data_detail(self)
	ret.hp = self:get_field("hp")
	ret.deadTime = self:get_field("deadTime")
	return ret
end

function mapObjectMonster:clear_data()
	self:set_field("subtype", 0)
	self:set_field("level", 0)
	self:set_field("hp", 0)
	self:set_field("ownUid", 0)
	self:set_field("deadTime", 0)
	self:set_position(0, 0)
end

return mapObjectMonster