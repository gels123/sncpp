--[[
	地图建筑矿
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local models = require "models"
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectCell = require "mapObjectCell"
local mapObjectBuildMine = class("mapObjectBuildMine", mapObjectCell)

-- override
function mapObjectBuildMine.get_db_fields()
    local db_fields = mapObjectBuildMine.super.get_db_fields()
    table.merge(db_fields, {
        __table__ = "mapobjectbuildmine",
        level = models.NumberField(), 		--等级
        status = models.NumberField(), 		--状态
        statusStartTime = models.NumberField(), --状态开始时间
        statusEndTime = models.NumberField(), --状态结束时间
        hp = models.NumberField(),          --耐久度
        ownUid = models.NumberField(),  	--归属玩家
        defender = models.TableField(),     --npc守军
        defenderCdTime = models.NumberField(), --npc守军恢复时间
        defenderNum = models.NumberField(),     --npc守军数量
        groupId = models.NumberField(),     --分组ID
        cumuValue = models.NumberField(),   --累积建造时长
        scoutInfo = models.TableField(), 	--被侦查信息
        shieldover = models.NumberField(),  --免战截止时间
        finish = models.NumberField(), 		--是否已建成
    })
    return db_fields
end

--初始化
function mapObjectBuildMine:init(params)
    assert(params.subtype and params.subtype >= 0)
    assert(params.level and params.level > 0)
    assert(params.status)
    assert(params.statusStartTime)
    assert(params.statusEndTime)
    assert(params.ownUid)
    assert(params.defender)
    assert(params.groupId and params.groupId >= 0)

    --状态异常, 报个错
    if mapConf.build_status.occupied <= params.status and params.status <= mapConf.build_status.not_settle and (not params.ownUid or params.ownUid <= 0) then
        gLog.e("mapObjectBuildMine:init error", params.x, params.y)
    end

    self.super.init(self, params)
    --gLog.dump(params, "mapObjectBuildMine:init create_object=", 10)
end

function mapObjectBuildMine:get_level()
    return self:get_field("level") or 0
end

function mapObjectBuildMine:clear_data()
    self:set_field("subtype", 0)
    self:set_field("level", 0)
    self:set_position(0, 0)
end

function mapObjectBuildMine:get_config()
    local subtype, level = self:getSubMapType(), self:get_level()
    return get_static_config().treasure[subtype][level]
end

--打包消息数据(详细信息)
function mapObjectBuildMine:pack_message_data_detail()
    local ret = self.super.pack_message_data_detail(self)
    local slaveOwnerAid = 0
    local uid = self:get_field("uid") or 0 --占领者玩家ID
    if uid and uid > 0 then
        local mapPlayer = mapCenter.mapPlayerMgr:get_player(uid)
        ret.uid = uid
        ret.name = mapPlayer and mapPlayer:get_name() or ""
        ret.head = mapPlayer and mapPlayer:get_head() or 1
        ret.aid = mapPlayer and mapPlayer:get_guild_id() or 0
        ret.abbr = mapPlayer and mapPlayer:get_guild_short() or ""
        ret.aname = mapPlayer and mapPlayer:get_guild_name() or ""

        local mapPlayerCity = mapCenter.mapObjectMgr.mapObjPlayerCityMgr:get_player_city(uid)
        if (mapPlayerCity:get_field("ownTime") or 0) > svrFunc.systemTime() then
            local slaveOwner = mapCenter.mapPlayerMgr:get_player(mapPlayerCity:get_field("ownUid"))
            slaveOwnerAid = slaveOwner and slaveOwner:get_guild_id() or 0
        end
    end
    local ownUid = self:get_field("ownUid") or 0 --拥有者玩家ID
    if ownUid and ownUid > 0 then
        local mapPlayer = mapCenter.mapPlayerMgr:get_player(ownUid)
        ret.ownName = mapPlayer and mapPlayer:get_name() or ""
        ret.ownHead = mapPlayer and mapPlayer:get_head() or 1
        ret.ownAbbr = mapPlayer and mapPlayer:get_guild_short() or ""
        ret.ownAname = mapPlayer and mapPlayer:get_guild_name() or ""

        if not uid or uid == 0 then
            local mapPlayerCity = mapCenter.mapObjectMgr.mapObjPlayerCityMgr:get_player_city(ownUid)
            if (mapPlayerCity:get_field("ownTime") or 0) > svrFunc.systemTime() then
                local slaveOwner = mapCenter.mapPlayerMgr:get_player(mapPlayerCity:get_field("ownUid"))
                slaveOwnerAid = slaveOwner and slaveOwner:get_guild_id() or 0
            end
        end
    end

    ret.slaveOwnerAid = slaveOwnerAid
    return ret
end

return mapObjectBuildMine