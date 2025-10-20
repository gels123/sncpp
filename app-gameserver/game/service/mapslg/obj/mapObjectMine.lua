--[[
	地图资源矿
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectMine = class("mapObjectMine", mapObjectCell)

-- override
function mapObjectMine.get_db_fields()
    local db_fields = mapObjectMine.super.get_db_fields()
    table.merge(db_fields, {
    	__table__ = "mapobjectmine",
    	level = models.NumberField(), 		--资源等级
   		remain_num = models.NumberField(),  --资源剩余量
    })
    return db_fields
end

--初始化
function mapObjectMine:init(params)
	assert(params.subtype and params.subtype > 0)
	assert(params.level and params.level > 0)
	assert(params.remain_num and params.remain_num > 0)
	
	self.super.init(self, params)
end

function mapObjectMine:get_level()
	return self:get_field("level") or 0
end

function mapObjectMine:clear_data()
	self:set_field("subtype", 0)
	self:set_field("level", 0)
	self:set_field("remain_num", 0)
    self:set_position(0, 0)
end

function mapObjectMine:get_config()
	local type, subtype, level = mapConf.queueType.attackBuildMine, self:getSubMapType(), self:get_level()
	local resource_buildings = get_static_config().resource_buildings
	return resource_buildings[type] and resource_buildings[type][subtype] and resource_buildings[type][subtype][level]
end

--打包消息数据(详细信息)
function mapObjectMine:pack_message_data_detail()
	local ret = self.super.pack_message_data_detail(self)
	local uid = self:get_field("uid") --占领者玩家ID
	if uid and uid > 0 then
		local mapPlayer = mapCenter.mapPlayerMgr:get_player(uid)
		ret.name = mapPlayer and mapPlayer:get_name() or ""
		ret.head = mapPlayer and mapPlayer:get_head() or 1
		ret.abbr = mapPlayer and mapPlayer:get_guild_short()
		ret.aname = mapPlayer and mapPlayer:get_guild_name()
	end
	return ret
end

return mapObjectMine