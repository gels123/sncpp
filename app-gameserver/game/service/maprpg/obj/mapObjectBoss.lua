--[[
	地图BOSS
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectBoss = class("mapObjectBoss", mapObjectCell)

-- override
function mapObjectBoss.get_db_fields()
    local db_fields = mapObjectBoss.super.get_db_fields()
    table.merge(db_fields, {
        __table__ = "mapobjectboss",
        level = models.NumberField(), 		--BOSS等级
        hp = models.NumberField(),          --BOSS HP
        deadTime = models.NumberField(),    --BOSS存活截止时间
        scoutInfo = models.TableField(), 	--被侦查信息
        defender = models.TableField(),     --BOSS守军
    })
    return db_fields
end

--初始化
function mapObjectBoss:init(params)
    assert(params.subtype and params.subtype > 0)
    assert(params.level and params.level > 0)
    assert(params.hp and params.hp > 0)
    assert(params.defender and next(params.defender))

    self.super.init(self, params)
end

--是否不存库
function mapObjectBoss:is_nosave()
    if self:get_field("cantRemove") then
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

function mapObjectBoss:get_level()
    return self:get_field("level") or 0
end

function mapObjectBoss:clear_data()
    self:set_field("subtype", 0)
    self:set_field("level", 0)
    self:set_position(0, 0)
end

function mapObjectBoss:get_config()
    local subtype, level = self:getSubMapType(), self:get_level()
    return get_static_config().treasure[subtype][level]
end

--打包消息数据(详细信息)
function mapObjectBoss:pack_message_data_detail()
    local ret = self.super.pack_message_data_detail(self)
    ret.hp = self:get_field("hp")
    ret.deadTime = self:get_field("deadTime")
    return ret
end

return mapObjectBoss