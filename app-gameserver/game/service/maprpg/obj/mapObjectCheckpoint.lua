--[[
	地图关卡
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectCheckpoint = class("mapObjectCheckpoint", mapObjectCell)

-- override
function mapObjectCheckpoint.get_db_fields()
    local db_fields = mapObjectCheckpoint.super.get_db_fields()
    table.merge(db_fields, {
        __table__ = "mapobjectcheckpoint",
        level = models.NumberField(), 		--等级
        status = models.NumberField(), 		--状态
        statusStartTime = models.NumberField(), --状态开始时间
        statusEndTime = models.NumberField(), --状态结束时间
        hp = models.NumberField(),          --耐久度
        ownAid = models.NumberField(),  	--归属联盟ID
        buildType = models.NumberField(),  	--联盟建筑类型
        buildFlag = models.NumberField(),     --联盟建筑状态标识
        buildTime = models.NumberField(),   --联盟建筑状态截止时间
        buildCdTime = models.NumberField(), --联盟建筑放弃等待截止时间
        buildUid = models.NumberField(),    --联盟建筑操作者
        isAct = models.BoolField(),  	    --是否激活
        defender = models.TableField(),     --npc守军
        defenderCdTime = models.NumberField(), --npc守军恢复时间
        defenderNum = models.NumberField(),     --npc守军数量
        scoutInfo = models.TableField(), 	--被侦查信息
        recoverTime = models.NumberField(), --恢复结算时间
        annouceTime = models.NumberField(), --宣战截止时间
        annouceInfo = models.TableField(), 	--宣战信息
        shieldover = models.NumberField(),  --免战截止时间
        costwheat = models.NumberField(),          --消耗的联盟币
        maxhp = models.NumberField(),          --耐久度
    })
    return db_fields
end

--初始化
function mapObjectCheckpoint:init(params)
    assert(params.subtype and params.subtype >= 0)
    assert(params.level and params.level > 0)
    assert(params.status)
    assert(params.statusStartTime)
    assert(params.statusEndTime)
    assert(params.hp)
    assert(params.ownAid)
    assert(params.buildType)
    assert(params.defender)

    self.super.init(self, params)
    --gLog.dump(params, "mapObjectCheckpoint:init create_object=", 10)
end

function mapObjectCheckpoint:get_level()
    return self:get_field("level") or 0
end

function mapObjectCheckpoint:clear_data()
    self:set_field("subtype", 0)
    self:set_field("level", 0)
    self:set_position(0, 0)
end

function mapObjectCheckpoint:get_config()
    local subtype, level = self:getSubMapType(), self:get_level()
    return get_static_config().treasure[subtype][level]
end

return mapObjectCheckpoint