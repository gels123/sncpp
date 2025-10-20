--[[
	地图宝箱
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectChest = class("mapObjectChest", mapObjectCell)

-- override
function mapObjectChest.get_db_fields()
    local db_fields = mapObjectChest.super.get_db_fields()
    table.merge(db_fields, {
    	__table__ = "mapobjectchest",
    	level = models.NumberField(), 		--宝箱等级
   		ownUid = models.NumberField(),      --宝箱归属玩家ID
   		hp = models.NumberField(),          --宝箱HP
		deadTime = models.NumberField(),    --宝箱存活截止时间
		taskID = models.NumberField(),  	--雷达任务ID
    })
    return db_fields
end

--初始化
function mapObjectChest:init(params)
	assert(params.subtype and params.subtype > 0)
	assert(params.level and params.level > 0)
	assert(params.ownUid and params.ownUid > 0)
	assert(params.hp and params.hp > 0)
	
	self.super.init(self, params)
end

function mapObjectChest:get_level()
	return self:get_field("level") or 0
end

function mapObjectChest:clear_data()
	self:set_field("subtype", 0)
	self:set_field("level", 0)
	self:set_field("ownUid", 0)
	self:set_field("hp", 0)
	self:set_field("deadTime", 0)
    self:set_position(0, 0)
end

function mapObjectChest:get_config()
	local subtype, level = self:getSubMapType(), self:get_level()
	return get_static_config().treasure[subtype][level]
end

--打包消息数据(详细信息)
function mapObjectChest:pack_message_data_detail()
	local ret = self.super.pack_message_data_detail(self)
	ret.hp = self:get_field("hp")
	ret.deadTime = self:get_field("deadTime")
	return ret
end

return mapObjectChest