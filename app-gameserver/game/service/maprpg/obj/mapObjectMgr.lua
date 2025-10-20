--[[
	地图对象管理
--]]
local skynet = require "skynet"
local mapConf = require "mapConf"
local mapUtils = require "mapUtils"
local publicLib = require "publicLib"
local searchLib = require "searchLib"
local common = require "common"
local cacheinterface = require("cacheinterface")
local queueLib = require("queueLib")
local queueUtils = require("queueUtils")
local mapCenter = require("mapCenter"):shareInstance()
local mapObjectMgr = class("mapObjectMgr")
local guildinterface = require "guildinterface"
local seasonLib = require "seasonLib"

--地图对象类型--对象类
local mapType2Class = 
{
    [mapConf.object_type.playercity] = require("mapObjectPlayerCity"),
    [mapConf.object_type.monster] = require("mapObjectMonster"),
    [mapConf.object_type.mine] = require("mapObjectMine"),
    [mapConf.object_type.chest] = require("mapObjectChest"),
    [mapConf.object_type.boss] = require("mapObjectBoss"),
    [mapConf.object_type.checkpoint] = require("mapObjectCheckpoint"),
    [mapConf.object_type.wharf] = require("mapObjectWharf"),
    [mapConf.object_type.city] = require("mapObjectCity"),
    [mapConf.object_type.commandpost] = require("mapObjectCommandPost"),
    [mapConf.object_type.station] = require("mapObjectStation"),
    [mapConf.object_type.buildmine] = require("mapObjectBuildMine"),
    [mapConf.object_type.fortress] = require("mapObjecFortress"),
    [mapConf.object_type.mill] = require("mapObjMill"),
}
--领地建筑接壤的领地相对坐标
local terrConnectDiff = {90000, -90000, 9, -9}

function mapObjectMgr:ctor()
	-- 所有地图对象
	self.objs = {}
    -- 玩家ID-拥有的地图对象-关联
    self.ownUidObjRef = {}
    -- 联盟ID-拥有的地图对象-关联(非领地建筑)
    self.ownAidObjRef = {}
    -- 联盟ID-拥有的地图对象-关联(领地建筑)
    self.ownAidTerrRef = {}
    -- 玩家属性
    self.ownUidAttr = {}
    -- 联盟属性
    self.ownAidAttr = {}
    -- 区域连通关系
    self.zoneconnect = {}

    -- 分类对象管理
    self.mapObjPlayerCityMgr = require("mapObjPlayerCityMgr").new()
    self.mapObjMonsterMgr = require("mapObjMonsterMgr").new()
    --self.mapObjMineMgr = require("mapObjMineMgr").new()
    self.mapObjChestMgr = require("mapObjChestMgr").new()
    self.mapObjBuildMineMgr = require("mapObjBuildMineMgr").new()
    self.mapObjBossMgr = require("mapObjBossMgr").new()
    self.mapObjTerrMgr = require("mapObjTerrMgr").new()
    self.mgrs = {
        [mapConf.object_type.playercity] = self.mapObjPlayerCityMgr,
        [mapConf.object_type.monster] = self.mapObjMonsterMgr,
        --[mapConf.object_type.mine] = self.mapObjMineMgr,
        [mapConf.object_type.chest] = self.mapObjChestMgr,
        [mapConf.object_type.buildmine] = self.mapObjBuildMineMgr,
        [mapConf.object_type.fortress] = self.mapObjBuildMineMgr,
        [mapConf.object_type.boss] = self.mapObjBossMgr,
        [mapConf.object_type.checkpoint] = self.mapObjTerrMgr,
        [mapConf.object_type.wharf] = self.mapObjTerrMgr,
        [mapConf.object_type.city] = self.mapObjTerrMgr,
        [mapConf.object_type.station] = self.mapObjTerrMgr,
        [mapConf.object_type.mill] = self.mapObjTerrMgr,
    }
end

-- 初始化
function mapObjectMgr:init()
    gLog.i("==mapObjectMgr:init begin==")
	-- 加载库数据
	self:loaddb()
    gLog.i("==mapObjectMgr:init 1==")

    for k, v in pairs(self.mgrs) do
        v:init()
    end

    for aid, _ in pairs(self.ownAidTerrRef) do
        self:calGuildAttr(aid, true)
    end

    -- 区域连通关系
    local zoneconnect = get_static_config().zoneconnect
    for k,v in pairs(zoneconnect) do
        local zone1, zone2, centerid = v.zone1, v.zone2, v.centerid
        if not self.zoneconnect[zone1] then
            self.zoneconnect[zone1] = {}
        end
        if not self.zoneconnect[zone1][zone2] then
            self.zoneconnect[zone1][zone2] = {}
        end
        table.insert(self.zoneconnect[zone1][zone2], centerid)
        local zone1, zone2 = zone2, zone1
        if not self.zoneconnect[zone1] then
            self.zoneconnect[zone1] = {}
        end
        if not self.zoneconnect[zone1][zone2] then
            self.zoneconnect[zone1][zone2] = {}
        end
        table.insert(self.zoneconnect[zone1][zone2], centerid)
    end
    --gLog.dump(self.zoneconnect, "mapObjectMgr:init zoneconnect=", 10)

    gLog.i("==mapObjectMgr:init end==")
end

-- 初始化完毕
function mapObjectMgr:init_over()
    gLog.d("mapObjectMgr:init_over")
    for k,v in pairs(self.mgrs) do
       v:init_over()
    end
    for uid, _ in pairs(self.ownUidObjRef) do
        self:calPlayerAttr(uid, true)
    end
end

-->>>>>>>>>>>>>>>>>>>>>>> 地图对象管理相关 >>>>>>>>>>>>>>>>>>>>>>>
-- 加载所有地图对象数据
function mapObjectMgr:loaddb()
	gLog.i("== mapObjectMgr:loaddb begin==")
    local w, h =  get_static_config().worldmap_globals.MapSize[1],  get_static_config().worldmap_globals.MapSize[2]
    local x, y = nil, nil
    for mapType,cls in pairs(mapType2Class) do
        local t_records = cls:get_db_table().select({type = mapType}, mapCenter.mapDB)
        for k,record in pairs(t_records) do
            --if svrconf.DEBUG and k == 1 then record:dump("mapObjectMgr:loaddb mapType="..mapType.." ") end
            x, y = record:get_field("x"), record:get_field("y")
            if x > w or y > h then
                gLog.w("mapObjectMgr:loaddb delete cross border obj", record:get_field("type"), record:get_field("subtype"), record:get_field("x"), record:get_field("y"))
                record:asyn_delete()
            else
                local obj = cls.new(record)
                self.objs[obj:get_objectid()] = obj
                self:add_object(obj, true)
            end
        end
    end
    ------ 地图固有建筑配置, 不存在, 则生成 ------
    --建造矿、碉堡
    local resource_mine = require("static.resource_mine")
    local resource_buildings = get_static_config().resource_buildings
    for k,v in pairs(resource_mine) do
        local obj = self:get_object(v.id)
        if not (obj and obj:getMapType() == v.Type and obj:get_field("groupId") == v.groupId) then
            local x, y = mapUtils.get_coord_xy(v.id)
            local w, h = mapUtils.get_obj_size(v.Type, v.SubType)
            --删除原地图对象
            for i=0,w-1,1 do
                for j=0,h-1,1 do
                    local obj2 = self:get_object(mapUtils.get_coord_id(x+i, y+j))
                    if obj2 then
                        self:remove_object(obj2)
                    end
                end
            end
            --创建地图对象
            local params = {
                objectid = v.id,
                type = v.Type,
                subtype = v.SubType or 0,
                x = x,
                y = y,
                level = v.level or 1,
                hp = resource_buildings[v.Type] and resource_buildings[v.Type][v.SubType] and resource_buildings[v.Type][v.SubType][v.level] and resource_buildings[v.Type][v.SubType][v.level].Endure or 0
            }
            if v.Type == mapConf.object_type.buildmine or v.Type == mapConf.object_type.fortress then --建筑矿额外字段
                params.status = mapConf.build_status.init
                params.statusStartTime = 0
                params.statusEndTime = 0
                params.ownUid = 0
                params.defender = mapUtils.randomDefenders(v.Type, 0, params.level)
                params.defenderCdTime = 0
                params.defenderNum = mapUtils.calcuDefenderNum(params.defender)
                params.groupId = v.groupId or 0
            end
            --if params.type == mapConf.object_type.fortress then gLog.dump(params, "mapObjectMgr:loaddb create_object1=", 10) end
            obj = self:create_object(params)
            obj:asyn_save()
        end
    end
    --据点: 关卡、码头、城市、联盟指挥所、车站、联盟磨坊
    local area = get_static_config().area
    for k,v in pairs(area) do
        if v.TerrBuild and v.TerrBuild.Type then
            local type, subtype, level = v.TerrBuild.Type, (v.TerrBuild.SubType or 0), (v.Level or 1)
            local x, y = v.Origin[1]+4, v.Origin[2]+4 --9*9据点中心点
            local id = mapUtils.get_coord_id(x, y)
            local w, h = mapUtils.get_obj_size(type, subtype, id)
            local obj = self:get_object(id)
            if not (obj and obj:getMapType() == type and obj:get_field("subtype") == subtype) then
                local mx, my = mapUtils.get_fix_xy(x, y, type, subtype, id)
                --删除原地图对象
                for i=0,w-1,1 do
                    for j=0,h-1,1 do
                        local obj = self:get_object(mapUtils.get_coord_id(mx+i, my+j))
                        if obj then
                            self:remove_object(obj)
                        end
                    end
                end
                --创建地图对象
                local defender = mapUtils.randomTerrDefenders(type, subtype, level)
                local maxhp = mapUtils:getRawTerrBuildHp(type, subtype, level)
                local params = {
                    objectid = id,
                    type = type,
                    subtype = subtype,
                    x = x,
                    y = y,
                    level = level,
                    status = mapConf.build_status.init,
                    statusStartTime = 0,
                    statusEndTime = 0,
                    hp = maxhp,
                    maxhp = maxhp,
                    ownAid = 0,
                    buildType = mapConf.guild_build_type.init,
                    isAct = false,
                    defender = defender,
                    defenderCdTime = 0,
                    defenderNum = mapUtils.calcuDefenderNum(defender),
                }
                --if params.type == mapConf.object_type.station then gLog.dump(params, "mapObjectMgr:loaddb create_object2=", 10) end
                obj = self:create_object(params)
                obj:asyn_save()
            else
                --做一下容错处理
                local maxHp= obj:get_field("maxhp") or 0
                if maxHp == 0 then
                    --做一下容错处理
                    maxHp = mapUtils:getRawTerrBuildHp(type, subtype, level)
                    obj:set_field("maxhp",maxHp)
                    obj:asyn_save()
                end
            end
        end
    end
	-- gLog.dump(self.objs, "mapObjectMgr:loaddb self.objs=", 10)
	gLog.i("== mapObjectMgr:loaddb end==")
end

-- 获取对象
function mapObjectMgr:get_object(objectid)
	return self.objs[objectid]
end

-- 增加对象
function mapObjectMgr:add_object(obj, isInit)
    --gLog.d("mapObjectMgr:add_object", obj:get_objectid())
	local objectid = obj:get_objectid()
    if self.objs[objectid] and self.objs[objectid] ~= obj then
        gLog.e("mapObjectMgr:add_object error, objectid=", objectid, "old=", self.objs[objectid]:pack_message_data(), "new=", obj:pack_message_data())
    end
	self.objs[objectid] = obj

    local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
    if not mapType then
        gLog.e("mapObjectMgr:add_object error2, objectid=", objectid, obj:pack_message_data())
    end
    assert(mapType)
    if self.mgrs[mapType] then
        self.mgrs[mapType]:add_object(obj)
    end

    -- 新增地图对象的定时器
    mapCenter.mapTimerMgr:addObjTimer(obj)

    mapCenter.mapMaskMgr:add_object(objectid, obj:get_range())

    mapCenter.mapAoiMgr:add_object(obj, isInit)

    -- 搜怪
    if mapConf.search_object_type[mapType] then
        local x, y = obj:get_field("x"), obj:get_field("y")
        publicLib:addFindMapObj(svrconf.kid, mapType, subMapType, level, obj:get_objectid(), x, y, mapCenter.mapMaskMgr:get_subzone(x, y))
    end
    -- 更新归属关联
    local ownUid = (mapType == mapConf.object_type.playercity and obj:get_playerid() or obj:get_field("ownUid"))
    if ownUid and ownUid > 0 then
        local ownAid = 0
        local mapPlayer = mapCenter.mapPlayerMgr:get_player(ownUid)
        if mapPlayer then
            ownAid = mapPlayer:get_guild_id() --服务器启动好后, 一般走这
        else
            ownAid = guildinterface.call_get_player_guildid(ownUid) or 0  --注意此处有时延迟2秒以上
        end
        -- 更新玩家ID-拥有的地图对象-关联
        if not self.ownUidObjRef[ownUid] then
            self.ownUidObjRef[ownUid] = {}
        end
        self.ownUidObjRef[ownUid][objectid] = objectid
        queueLib:updateOwnUidObjRef(svrconf.kid, objectid, nil, ownUid, nil, ownAid)
        self:calPlayerAttr(ownUid)
        -- 联盟ID-拥有的地图对象-关联
        if ownAid > 0 then
            if not self.ownAidObjRef[ownAid] then
                self.ownAidObjRef[ownAid] = {}
            end
            self.ownAidObjRef[ownAid][objectid] = obj
            queueLib:updateOwnAidObjRef(svrconf.kid, objectid, nil, ownAid)
        end
    end
    local ownAid = obj:get_field("ownAid")
    if ownAid and ownAid > 0 and mapConf.terr_object_type[mapType] then
        if not self.ownAidTerrRef[ownAid] then
            self.ownAidTerrRef[ownAid] = {}
        end
        self.ownAidTerrRef[ownAid][objectid] = obj
        queueLib:updateOwnAidObjRef(svrconf.kid, objectid, nil, ownAid)
        self:calGuildAttr(ownAid)
        self:updateTerrAct(ownAid)
        if obj:get_field("isAct") then
            if mapType == mapConf.object_type.station then
                searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), ownAid)
            elseif mapType == mapConf.object_type.checkpoint or mapType == mapConf.object_type.wharf then
                searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), ownAid)
            end
        end
    end
end

-- 删除对象
function mapObjectMgr:remove_object(obj, more)
	local objectid = obj:get_objectid()
	self.objs[objectid] = nil
    obj:asyn_delete()

    local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
    if self.mgrs[mapType] then
        self.mgrs[mapType]:remove_object(obj)
    end
    
    -- 删除地图对象定时器
    mapCenter.mapTimerMgr:removeObjTimer(objectid)

    mapCenter.mapAoiMgr:remove_object(obj, more)

    mapCenter.mapMaskMgr:remove_object(objectid, obj:get_range())

    -- 搜怪
    if mapConf.search_object_type[mapType] then
        publicLib:delFindMapObj(svrconf.kid, mapType, subMapType, level, obj:get_objectid(), mapCenter.mapMaskMgr:get_subzone(obj:get_field("x"), obj:get_field("y")))
    end
    -- 侦查
    if mapConf.scout_object_type[obj:getMapType()] then
        mapCenter:cancelScout(obj, 4032)
    end
    -- 更新归属关联
    local ownUid = (mapType == mapConf.object_type.playercity and obj:get_playerid() or obj:get_field("ownUid"))
    if ownUid and ownUid > 0 then
        local ownAid = guildinterface.call_get_player_guildid(ownUid) or 0
        -- 更新玩家ID-拥有的地图对象-关联
        if self.ownUidObjRef[ownUid] then
            self.ownUidObjRef[ownUid][objectid] = nil
            if not next(self.ownUidObjRef[ownUid]) then
                self.ownUidObjRef[ownUid] = nil
            end
        end
        queueLib:updateOwnUidObjRef(svrconf.kid, objectid, ownUid, nil, ownAid, nil)
        self:calPlayerAttr(ownUid)
        -- 联盟ID-拥有的地图对象-关联
        if ownAid > 0 then
            if self.ownAidObjRef[ownAid] then
                self.ownAidObjRef[ownAid][objectid] = nil
                if not next(self.ownAidObjRef[ownAid]) then
                    self.ownAidObjRef[ownAid] = nil
                end
                queueLib:updateOwnAidObjRef(svrconf.kid, objectid, ownAid, nil)
            end
        end
    end
    local ownAid = obj:get_field("ownAid")
    if ownAid and ownAid > 0 and mapConf.terr_object_type[mapType] then
        if self.ownAidTerrRef[ownAid] then
            self.ownAidTerrRef[ownAid][objectid] = nil
            if not next(self.ownAidTerrRef[ownAid]) then
                self.ownAidTerrRef[ownAid] = nil
            end
            queueLib:updateOwnAidObjRef(svrconf.kid, objectid, ownAid, nil)
            self:calGuildAttr(ownAid)
            self:updateTerrAct(ownAid)
            if mapType == mapConf.object_type.station then
                searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
            elseif mapType == mapConf.object_type.checkpoint or mapType == mapConf.object_type.wharf then
                searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
            end
        end
    end
end

-- 创建地图对象
function mapObjectMgr:create_object(params)
    --gLog.dump(params, "mapObjectMgr:create_object params=", 10)
    assert(params.type and params.x and params.y)
    local cls = mapType2Class[params.type]
    assert(cls)
    local objectid = mapUtils.get_coord_id(params.x, params.y)
    local record = cls:get_db_table().create(objectid, mapCenter.mapDB)
    local obj = cls.new(record)
    obj:init(params)
    self:add_object(obj)
	return obj
end

function mapObjectMgr:isOwnObj(ownUid, objids)
    if self.ownUidObjRef[ownUid] then
        for _,objid in pairs(objids) do
            if self.ownUidObjRef[ownUid][objid] then
                return true
            end
        end
    end
end

function mapObjectMgr:getOwnObjs(ownUid)
    return self.ownUidObjRef[ownUid]
end

-- 一些字段更新后需要执行更多逻辑
function mapObjectMgr:doMoreLogicAttrs(obj, logicAttrs)
    if svrconf.DEBUG then
        gLog.dump(logicAttrs, "mapObjectMgr:doMoreLogicAttrs objid="..obj:get_objectid(), 10)
    end
    local gateLib = require("gateLib")
    local objid, mapType, subMapType, level = obj:get_objectid(), obj:getMapType(), obj:getSubMapType(), obj:get_level()
    for k,v in pairs(logicAttrs) do
        if k == mapConf.moreLogicAttrs.ownUid then
            -- 更新地图对象信息
            obj:set_pack(true)
            if mapType == mapConf.object_type.playercity then -- 玩家城堡, 注意玩家城堡的ownUid表示奴隶主, 不能有ownUidObjRef关联
                gateLib:sendPlayer(svrconf.kid, obj:get_playerid(), "sync_mapcity", obj:pack_message_data())
            elseif mapType == mapConf.object_type.buildmine or mapType == mapConf.object_type.fortress then -- 资源地、碉堡
                -- 更新玩家ID-拥有的地图对象-关联、更新联盟ID-拥有的地图对象-关联
                local oldUid, newUid, oldAid, newAid = v[1], v[2], nil, nil
                if oldUid and oldUid > 0 then
                    if self.ownUidObjRef[oldUid] then
                        self.ownUidObjRef[oldUid][objid] = nil
                        if not next(self.ownUidObjRef[oldUid]) then
                            self.ownUidObjRef[oldUid] = nil
                        end
                        gateLib:sendMsgToPlayer(svrconf.kid, oldUid, "synclostbuildmines", {objid = objid,})
                        -- 里程碑占领x级以上资源地y块(丢失要扣除)
                        if mapType == mapConf.object_type.buildmine then
                            gateLib:sendPlayer(svrconf.kid, oldUid, "lose_buildmine_event", level)
                        end
                        self:calPlayerAttr(oldUid)
                    end
                    oldAid = guildinterface.call_get_player_guildid(oldUid) or 0
                    if oldAid > 0 then
                        if self.ownAidObjRef[oldAid] and self.ownAidObjRef[oldAid][objid] then
                            self.ownAidObjRef[oldAid][objid] = nil
                            if not next(self.ownAidObjRef[oldAid]) then
                                self.ownAidObjRef[oldAid] = nil
                            end
                        end
                    end
                end
                if newUid and newUid > 0 then
                    if not self.ownUidObjRef[newUid] then
                        self.ownUidObjRef[newUid] = {}
                    end
                    if not self.ownUidObjRef[newUid][objid] then
                        self.ownUidObjRef[newUid][objid] = objid
                        if mapType == mapConf.object_type.buildmine or mapType == mapConf.object_type.fortress then
                            require("gateLib"):sendMsgToPlayer(svrconf.kid, newUid, "syncgetbuildmines", {cell = obj:pack_message_data(),})
                            self:calPlayerAttr(newUid)
                        end
                    end
                    newAid = guildinterface.call_get_player_guildid(newUid) or 0
                    if newAid > 0 then
                        if not self.ownAidObjRef[newAid] then
                            self.ownAidObjRef[newAid] = {}
                        end
                        if not self.ownAidObjRef[newAid][objid] then
                            self.ownAidObjRef[newAid][objid] = obj
                        end
                    end
                end
                if (oldUid and oldUid > 0) or (newUid and newUid > 0) then
                    queueLib:updateOwnUidObjRef(svrconf.kid, objid, oldUid, newUid, oldAid, newAid)
                end
                if (oldAid and oldAid > 0) or (newAid and newAid > 0) then
                    queueLib:updateOwnAidObjRef(svrconf.kid, objid, oldAid, newAid)
                end
                -- 取消侦查
                if newUid and newUid > 0 then
                    if mapCenter:cancelScout(obj, nil, {[newUid] = true,}) then
                        obj:asyn_save()
                    end
                --    if mapConf.search_object_type[mapType] then --搜怪
                --        publicLib:delFindMapObj(svrconf.kid, mapType, subMapType, level, objid, mapCenter.mapMaskMgr:get_subzone(obj:get_field("x"), obj:get_field("y")))
                --    end
                --else
                --    if mapConf.search_object_type[mapType] then --搜怪
                --        local x, y = obj:get_field("x"), obj:get_field("y")
                --        publicLib:addFindMapObj(svrconf.kid, mapType, subMapType, level, obj:get_objectid(), x, y, mapCenter.mapMaskMgr:get_subzone(x, y))
                --    end
                end
            end
        elseif k == mapConf.moreLogicAttrs.shieldover and  mapType == mapConf.object_type.buildmine  and v[2] > 0 then
            --开启保护罩
            gLog.i("mapCenter:updateMapObjPro 资源地开启护盾....",objid)
            mapCenter:cancelScout(obj, 4034)
        elseif mapConf.object_type.buildmine == mapType and k == mapConf.moreLogicAttrs.status then
            local ownUid = obj:get_field("ownUid")
            local _, status = v[1], v[2]
            if ownUid and ownUid > 0 and status == mapConf.build_status.settled then
                self:calPlayerAttr(ownUid)
            end
        elseif mapConf.terr_object_type[mapType] and k == mapConf.moreLogicAttrs.ownAid then
            -- 更新地图对象信息
            obj:set_pack(true)
            -- 更新联盟ID-拥有的地图对象-关联
            local oldAid, newAid = v[1], v[2]
            gLog.d("mapObjectMgr:doMoreLogicAttrs ownAid do1 objid=", obj:get_objectid(), oldAid, newAid)
            if oldAid > 0 then
                if self.ownAidTerrRef[oldAid] and self.ownAidTerrRef[oldAid][objid] then
                    self.ownAidTerrRef[oldAid][objid] = nil
                    if not next(self.ownAidTerrRef[oldAid]) then
                        self.ownAidTerrRef[oldAid] = nil
                    end
                    self:updateTerrAct(oldAid)
                    self:calGuildAttr(oldAid)
                    if mapType == mapConf.object_type.station then
                        searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
                    elseif mapType == mapConf.object_type.checkpoint or mapType == mapConf.object_type.wharf then
                        searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
                    end
                    require("gateLib"):sendGuildPlayers(svrconf.kid, oldAid, "send2client", "synrmterrbuildinfo", {objid = objid,}) --同步移除领地
                    --联盟领地变动事件
                    seasonLib:GuildLnadEvent(svrconf.kid, oldAid, mapType, subMapType, level, -1)
                    --如果没有大要塞，解散联邦
                    if mapType == mapConf.object_type.city and subMapType == mapConf.city_type.mid and self:getTerrLnadNumType({oldAid}, mapType, subMapType, 1) <=0 then
                        guildinterface.dissolveBigGuild(oldAid)
                    end
                    --地图领地对象激活状态变化，需要更新此领地上的玩家领地盾状态
                    guildinterface.update_guild_member_land_shield(oldAid, obj:get_field("x"), obj:get_field("y"))
                end
            end
            if newAid > 0 then
                if not self.ownAidTerrRef[newAid] then
                    self.ownAidTerrRef[newAid] = {}
                end
                if not self.ownAidTerrRef[newAid][objid] then
                    self.ownAidTerrRef[newAid][objid] = obj
                    self:calGuildAttr(newAid)
                    self:updateTerrAct(newAid)
                    if obj:get_field("isAct") then
                        if mapType == mapConf.object_type.station then
                            searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), newAid)
                        elseif mapType == mapConf.object_type.checkpoint or mapType == mapConf.object_type.wharf then
                            searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), newAid)
                        end
                        --地图领地对象激活状态变化，需要更新此领地上的玩家领地盾状态
                        guildinterface.update_guild_member_land_shield(newAid, obj:get_field("x"), obj:get_field("y"))
                    end
                    local ret = guildinterface.get_tech_attr(newAid, {"Guild_Manor_Hp"})
                    if ret and ret.Guild_Manor_Hp then
                        self:onGuildMaxHpChange(obj, ret.Guild_Manor_Hp,false)
                    end
                    --联盟领地变动事件
                    seasonLib:GuildLnadEvent(svrconf.kid, newAid, mapType, subMapType, level, 1)
                end
            end
            if (oldAid and oldAid > 0) or (newAid and newAid > 0) then
                queueLib:updateOwnAidObjRef(svrconf.kid, objid, oldAid, newAid)
            end
            -- 取消侦查
            if newAid and newAid > 0 then
                local uids = require("guildinterface").get_guild_member_ids(newAid) or {}
                if mapCenter:cancelScout(obj, nil, table.turnvalues(uids)) then
                    obj:asyn_save()
                end
            end
        elseif mapConf.terr_object_type[mapType] and k == mapConf.moreLogicAttrs.isAct then
            -- 更新地图对象信息
            gLog.d("更新地图对象信息",k ,v[2],obj:get_field("ownAid"))
            obj:set_pack(true)
            -- 更新联盟ID-拥有的地图对象-关联
            local isAct, ownAid = v[2], obj:get_field("ownAid")
            if mapType == mapConf.object_type.station then
                if isAct and ownAid and ownAid > 0 then
                    searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), ownAid)
                else
                    searchLib:updateRailwayMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
                    queueLib:onRailwayLoseAct(svrconf.kid, objid, ownAid)
                end
            elseif mapType == mapConf.object_type.checkpoint or mapType == mapConf.object_type.wharf then
                if isAct and ownAid and ownAid > 0 then
                    searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), ownAid)
                else
                    searchLib:updateCheckMap(svrconf.kid, obj:get_field("x"), obj:get_field("y"), 0)
                    queueLib:onCheckpointLoseAct(svrconf.kid, objid, ownAid)
                end
            end
            if isAct then
                local ret = guildinterface.get_tech_attr(ownAid, {"Guild_Manor_Hp"})
                if ret and ret.Guild_Manor_Hp then
                    self:onGuildMaxHpChange(obj,ret.Guild_Manor_Hp,true)
                end
            end
            --地图领地对象激活状态变化，需要更新此领地上的玩家领地盾状态
            guildinterface.update_guild_member_land_shield(ownAid, obj:get_field("x"), obj:get_field("y"))
        elseif mapConf.terr_object_type[mapType] and k == mapConf.moreLogicAttrs.buildType then
            -- 更新地图对象信息  联盟建筑类型变化
            obj:set_pack(true)
            -- 刷新领地激活状态
            local ownAid = obj:get_field("ownAid")
            if ownAid and ownAid > 0 then
                self:updateTerrAct(ownAid)
            end
            local ret = ownAid and ownAid > 0 and guildinterface.get_tech_attr(ownAid, {"Guild_Manor_Hp"}) or nil
            self:onGuildMaxHpChange(obj, ret and ret.Guild_Manor_Hp or nil,true)
        elseif k == mapConf.moreLogicAttrs.annouceTime then
            -- 更新地图对象信息
            obj:set_pack(true)
            -- 刷新领地激活状态
            local annouceTime, annouceAid = v[2], logicAttrs.annouceAid and logicAttrs.annouceAid[2]
            if annouceTime and annouceTime > 0 then
                if annouceAid and annouceAid > 0 then
                    local annouceInfo = obj:get_field("annouceInfo")
                    gLog.d("mapObjectMgr:doMoreLogicAttrs annouceTime do1=", objid, annouceTime, annouceAid, annouceInfo)
                    annouceInfo[annouceAid] = annouceTime
                    for _,time in pairs(annouceInfo) do
                        if time > annouceTime then
                            annouceTime = time
                        end
                    end
                    obj:set_field("annouceTime", annouceTime)
                    obj:set_field("annouceInfo", annouceInfo)
                    if mapCenter.mapTimerMgr.timerCfg[mapType] and mapCenter.mapTimerMgr.timerCfg[mapType][k] then
                        mapCenter.mapTimerMgr:doUpdate(objid, k, annouceTime)
                    end
                end
            else
                if annouceAid and annouceAid > 0 then -- 清除一个联盟的宣战信息
                    local annouceInfo = obj:get_field("annouceInfo")
                    if annouceInfo[annouceAid] then
                        gLog.d("mapObjectMgr:doMoreLogicAttrs annouceTime do2=", objid, annouceTime, annouceAid, annouceInfo)
                        annouceInfo[annouceAid] = nil
                        local ti = 0
                        for _,time in pairs(annouceInfo) do
                            if ti == 0 or time > ti then
                                ti = time
                            end
                        end
                        obj:set_field("annouceTime", ti)
                        obj:set_field("annouceInfo", annouceInfo)
                        if mapCenter.mapTimerMgr.timerCfg[mapType] and mapCenter.mapTimerMgr.timerCfg[mapType][k] then
                            mapCenter.mapTimerMgr:doUpdate(objid, k, ti)
                        end
                    end
                else -- 清除所有宣战信息
                    local guildinterface = require("guildinterface")
                    local annouceInfo, ownAid = obj:get_field("annouceInfo"), obj:get_field("ownAid")
                    gLog.d("mapObjectMgr:doMoreLogicAttrs annouceTime do3=", objid, annouceTime, annouceAid, ownAid, annouceInfo)
                    for kAid,_ in pairs(annouceInfo) do
                        if kAid ~= ownAid then
                            guildinterface.announceCancel(kAid, objid, ownAid, true)
                        end
                    end
                    obj:set_field("annouceTime", 0)
                    obj:set_field("annouceInfo", {})
                    if mapCenter.mapTimerMgr.timerCfg[mapType] and mapCenter.mapTimerMgr.timerCfg[mapType][k] then
                        mapCenter.mapTimerMgr:doUpdate(objid, k, 0)
                        skynet.timeout(100, function()
                            queueLib:backOccupyCloneQueue(svrconf.kid, objid)
                        end)
                    end
                end
            end
        end
    end
end

--local guild_Manor_Hp = guildinterface.get_tech_attr(newAid, {"Guild_Manor_Hp"})
function mapObjectMgr:onGuildMaxHpChange(obj, guild_Manor_Hp, isAddHp)
    skynet.fork(function()
        --要根据新联盟更新最大耐久
        local buildType = obj:get_field("buildType") or -1
        local buildFlag = obj:get_field("buildFlag") or -1
        local isBuildCenter = (buildType == mapConf.guild_build_type.center and buildFlag~=1)
        local rawMaxHp = mapUtils:getRawTerrBuildHp(obj:getMapType(), obj:getSubMapType(), obj:get_level(),isBuildCenter)
        local maxHp =  rawMaxHp
        gLog.d("onGuildMaxHpChange getRawTerrBuildHp:",obj:get_objectid(),isBuildCenter,buildType,buildFlag,guild_Manor_Hp,isAddHp,maxHp)
        if guild_Manor_Hp and guild_Manor_Hp > 0 then
            maxHp = maxHp * (1 + guild_Manor_Hp / 1000)
        end
        local oldMaxHp = obj:get_field("maxhp") or 0
        local oldHp = obj:get_field("hp") or 0
        if maxHp ~= oldMaxHp then
            local updatePro = {}
            updatePro.maxhp = maxHp
            if isAddHp then
                if maxHp > oldMaxHp then
                    updatePro.hp = (oldHp or 0) + (maxHp - oldMaxHp)
                    --不能超过上限
                    if updatePro.hp > maxHp then
                        updatePro.hp = maxHp
                    end
                else
                    updatePro.hp = maxHp
                end
            end
            mapCenter:updateMapObjPro(obj:get_objectid(), nil, updatePro)
            gLog.d("联盟领地更新最大血量值",oldMaxHp,rawMaxHp,maxHp,obj:get_objectid(),obj:getMapType(), obj:getSubMapType(), obj:get_level())
        end
    end)
end

-- 玩家联盟发生变化
function mapObjectMgr:onGuildIdChange(uid, oldAid, aid)
    if self.ownUidObjRef[uid] then
        for _,objid in pairs(self.ownUidObjRef[uid]) do
            local obj = self.objs[objid]
            if obj then
                -- 更新地图对象信息
                obj:set_pack(true)
                mapCenter.mapAoiMgr:update_object(obj)
                --
                local ownUid = (obj:getMapType() == mapConf.object_type.playercity and obj:get_playerid() or obj:get_field("ownUid"))
                if ownUid and ownUid > 0 then
                    queueLib:updateOwnUidObjRef(svrconf.kid, objid, nil, ownUid, nil, aid)
                end
                -- 更新联盟ID-拥有的地图对象-关联
                local objid = obj:get_objectid()
                if oldAid and oldAid > 0 and self.ownAidObjRef[oldAid] then
                    self.ownAidObjRef[oldAid][objid] = nil
                    if not next(self.ownAidObjRef[oldAid]) then
                        self.ownAidObjRef[oldAid] = nil
                    end
                end
                if aid and aid > 0 then
                    if not self.ownAidObjRef[aid] then
                        self.ownAidObjRef[aid] = {}
                    end
                    self.ownAidObjRef[aid][objid] = obj
                end
                if (oldAid and oldAid > 0) or (aid and aid > 0) then
                    queueLib:updateOwnAidObjRef(svrconf.kid, objid, oldAid, aid)
                end
            end
        end
    end

    --更新所以奴隶的奴隶主联盟ID
    local ok, pids = require("gateLib"):callPlayerEx(svrconf.kid, uid, "get_player_slave_uid")
    if next(pids) then
        for i, v in ipairs(pids) do
            local mapPlayerCity = self:get_player_city(v)
            mapPlayerCity:set_pack(true)
            require("gateLib"):sendPlayer(svrconf.kid, v, "sync_mapcity", mapPlayerCity:pack_message_data())
        end
    end
end

-- 获取local变量
function mapObjectMgr:getMapType2Class()
    return mapType2Class
end
--<<<<<<<<<<<<<<<<<<<<<<< 地图对象管理相关 <<<<<<<<<<<<<<<<<<<<<<<



-->>>>>>>>>>>>>>>>>>>>>>> 玩家城堡相关 >>>>>>>>>>>>>>>>>>>>>>>
-- 获取玩家城堡
function mapObjectMgr:get_player_city(playerid)
    return self.mapObjPlayerCityMgr:get_player_city(playerid)
end
--<<<<<<<<<<<<<<<<<<<<<<< 玩家城堡相关 <<<<<<<<<<<<<<<<<<<<<<<


-->>>>>>>>>>>>>>>>>>>>>>> 地图对象倒计时相关 >>>>>>>>>>>>>>>>>>>>>>>
-- 地图对象定时器回调统一入口
function mapObjectMgr:timerCallback(param)
    --gLog.dump(param, "mapObjectMgr:timerCallback param=", 10)
    local id = param.id
    local timerType = param.timerType
    local hasTimer = mapCenter.mapTimerMgr:removeObjTimer(id, timerType)
    -- 仅成功删除当前定时器时才触发回调逻辑
    if hasTimer then
        local obj = self:get_object(id)
        if not obj then
            gLog.w("mapObjectMgr:timerCallback failed1: not found", id, timerType)
            return
        end
        if timerType ~= "pack" then
            gLog.i("mapObjectMgr:timerCallback=", id, timerType,obj:getMapType())
        end
        local curTime = svrFunc.systemTime()
        if timerType == "pack" then
            -- 缓存数据过期时间回调
            obj:clean_pack()
        elseif timerType == "deadTime" then
            -- 存活截止时间回调
            skynet.fork(function ()
                self:remove_object(obj)
            end)
        elseif timerType == "shieldover" then
            -- 保护罩截止时间回调
            if obj:getMapType() == mapConf.object_type.buildmine then
                -- 资源地保护罩截止时间回调
                skynet.fork(function ()
                    mapCenter:updateMapObjPro(id, nil,{shieldover=0})
                    gLog.d("resourceshieldover 保护罩截止时间回调，发送推送pushSomeOne:","playerid:",obj:get_field("ownUid"))
                    --require ("pushLib"):send(svrconf.kid, "pushSomeOne", obj:get_playerid(), 105)
                    if obj:get_field("ownUid") > 0 then
                        require ("gateLib"):callPlayerEx(svrconf.kid, obj:get_field("ownUid"), "brokenBuildMineProtectBuff")
                    end
                end)
            else
                skynet.fork(function ()
                    mapCenter:update_player_info(obj:get_playerid(), timerType, 0)
                    gLog.d("保护罩截止时间回调，发送推送pushSomeOne:","playerid:",obj:get_playerid())
                    require ("pushLib"):send(svrconf.kid, "pushSomeOne", obj:get_playerid(), 105)
                end)
            end
        elseif timerType == "skintime" then
            -- 皮肤截止时间回调
            skynet.fork(function ()
                mapCenter:update_player_info(obj:get_playerid(), timerType, 0)
                require("gateLib"):sendPlayerEx(svrconf.kid, obj:get_playerid(), "onPlayerSkinExpire")
            end)
        elseif timerType == "landshieldover" then
            -- 领地盾截止时间回调
            skynet.fork(function ()
                mapCenter:updateMapObjPro(id, nil,{landshieldover=0})
            end)
        elseif timerType == "recoverTime" then
            -- 恢复结算时间回调
            skynet.fork(function ()
                local mapType, subMapType, level, hp = obj:getMapType(), obj:getSubMapType(), obj:get_level(), obj:get_field("hp")
                local maxHp = 0 -- 最大耐久
                local walllv = 1
                if mapType == mapConf.object_type.fortress then
                    local resource_buildings = get_static_config().resource_buildings
                    maxHp = resource_buildings[mapType] and resource_buildings[mapType][subMapType] and resource_buildings[mapType][subMapType][level] and resource_buildings[mapType][subMapType][level].Endure or 0
                elseif mapConf.terr_object_type[mapType] then
                    maxHp= obj:get_field("maxhp") or 0
                    if maxHp == 0 then
                        --做一下容错处理
                        local area_battle = get_static_config().area_battle
                        maxHp = area_battle[mapType] and area_battle[mapType][subMapType] and area_battle[mapType][subMapType][level] and area_battle[mapType][subMapType][level].Stamina or 0
                    end
                elseif mapType == mapConf.object_type.playercity then
                    local mapPlayer = mapCenter.mapPlayerMgr:get_player(obj:get_playerid())
                    walllv = mapPlayer and mapPlayer:get_walllv() or 1
                    maxHp = mapUtils:getPlayerCitydurability(walllv)
                end
                local updatePro = {}
                if hp < maxHp then
                    local recoverHp = queueUtils:getTerrHpRecover(mapType, maxHp, walllv)
                    local recoverCd = queueUtils:getHpRecoverTime(mapType,walllv)
                    hp = hp + recoverHp
                    if hp > maxHp then
                        hp = maxHp
                    end
                    updatePro.hp = hp
                    updatePro.recoverTime = curTime + recoverCd
                    if mapType == mapConf.object_type.playercity then
                        updatePro.recoverEndTime = curTime + math.ceil((maxHp - hp)/recoverHp) * recoverCd
                    end
                    mapCenter:updateMapObjPro(id, nil, updatePro)
                else
                    updatePro.hp = maxHp
                    updatePro.recoverTime = 0
                    if mapType == mapConf.object_type.playercity then
                        updatePro.recoverEndTime = 0
                    end
                    mapCenter:updateMapObjPro(id, nil, updatePro)
                end
                if mapType == mapConf.object_type.playercity then
                    require("gateLib"):sendPlayer(svrconf.kid, obj:get_playerid(), "mapSyncData", updatePro.hp, updatePro.recoverEndTime, updatePro.recoverTime)
                end
            end)
        elseif timerType == "ownTime" then
            -- 归属玩家截止时间回调
            skynet.fork(function ()
                local mapType = obj:getMapType()
                if mapType == mapConf.object_type.playercity then --玩家城堡
                    local ownUid = obj:get_field("ownUid") or 0
                    -- 自动解除俘虏
                    if ownUid > 0 then
                        local slaveUId = obj:get_playerid()
                        mapCenter:updateSlave(slaveUId, ownUid)

                        local mailLib = require("mailLib")
                        local pushLib = require("pushLib")
                        local infos = require("cacheinterface").call_get_player_info({ownUid, slaveUId}, {"name", "head", "border", "guildshort"}) or {}

                        local pushInfo = {
                            name            = infos[ownUid] and infos[ownUid].name or "",
                            guildshort      = infos[ownUid] and infos[ownUid].guildshort or "",
                            slavename       = infos[slaveUId] and infos[slaveUId].name or "",
                            slaveguildshort = infos[slaveUId] and infos[slaveUId].guildshort or "",
                        }

                        --给俘虏发邮件
                        local mailData = {
                            data = infos[ownUid] or {},
                        }
                        mailLib:sendMail(svrconf.kid, 0, {slaveUId}, 6302, mailData)

                        --给俘虏推送
                        pushLib:send(svrconf.kid, "pushSomeOne", slaveUId, 1002, pushInfo.guildshort, pushInfo.name)

                        --给奴役者发邮件
                        mailData = {
                            data = infos[slaveUId] or {}
                        }
                        local slave = require("gateLib"):callPlayerEx(svrconf.kid, ownUid, "get_slave", slaveUId)
                        mailData.data.textlist = { pushInfo.slavename, slave.Water or 0, slave.Food or 0 }
                        mailLib:sendMail(svrconf.kid, 0, {ownUid}, 6311, mailData)
                        --给奴役者推送
                        pushLib:send(svrconf.kid, "pushSomeOne", ownUid, 1003, pushInfo.slaveguildshort, pushInfo.slavename)
                        require("pushLib"):send(svrconf.kid, "removeSomeOneLater", ownUid, string.format("rob_slave%s",slaveUId))

                        --运营日志
                        skynet.fork(function()
                            local logData = {}
                            logData.slaver_id = ownUid
                            logData.escape_type = 0
                            require("logLib"):writeLog4Gm(slaveUId, gLogEvent.slave_normal_escape, logData)
                        end)
                    end
                else --碉堡
                    -- 再次确认未拥有分组内任何一个建筑矿, 则移除归属信息
                    local ownUid, ownTime, groupId = obj:get_field("ownUid"), obj:get_field("ownTime"), obj:get_field("groupId")
                    if ownUid and ownUid > 0 and ownTime and ownTime > 0 then
                        local mineIds = get_static_config().group_resource_mine[groupId]
                        if mineIds and #mineIds > 0 and not mapCenter:isOwnObj(ownUid, mineIds) then
                            gLog.i("mapObjectMgr:timerCallback remove ownUid=", ownUid, "id=", id)
                            local updatePro = {
                                ownUid = 0,
                                ownAid = 0,
                                ownTime = 0,
                            }
                            mapCenter:updateMapObjPro(id, nil, updatePro)
                        end
                    end
                end
            end)
        elseif timerType == "buildTime" then
            -- 联盟建筑状态截止时间
            skynet.fork(function ()
                -- 再次确认未拥有分组内任何一个建筑矿, 则移除归属信息
                local ownAid, buildFlag, buildUid, x, y = obj:get_field("ownAid"), obj:get_field("buildFlag"), obj:get_field("buildUid"), obj:get_field("x"), obj:get_field("y")
                if ownAid and ownAid > 0 then
                    gLog.i("mapObjectMgr:timerCallback buildTime=", id, ownAid, buildFlag, buildUid)
                    local mapPlayer = mapCenter.mapPlayerMgr:get_player(buildUid)
                    if buildFlag == 1 then -- 设置
                        local updatePro = {
                            buildFlag = 0,
                            buildTime = 0,
                        }
                        mapCenter:updateMapObjPro(id, nil, updatePro)
                        -- 更新领地建筑激活状态
                        self:updateTerrAct(ownAid)
                        -- 设置成功全盟邮件
                        require("mailLib"):sendAllianceMail(svrconf.kid, 0, ownAid, 4411, {data = {x = x, y = y, name = mapPlayer and mapPlayer:get_name() or "",},})
                    elseif buildFlag == 2 then -- 取消
                        local updatePro = {
                            buildType = mapConf.guild_build_type.init,
                            buildFlag = 0,
                            buildTime = 0,
                        }
                        mapCenter:updateMapObjPro(id, nil, updatePro)
                        -- 取消成功全盟邮件
                        require("mailLib"):sendAllianceMail(svrconf.kid, 0, ownAid, 4412, {data = {x = x, y = y, name = mapPlayer and mapPlayer:get_name() or "",},})
                    elseif buildFlag == 3 then -- 放弃
                        queueLib:giveUpOwnedObj(svrconf.kid, nil, id, ownAid)
                        -- 放弃成功全盟邮件
                        require("mailLib"):sendAllianceMail(svrconf.kid, 0, ownAid, 4409, {data = {x = x, y = y, name = mapPlayer and mapPlayer:get_name() or "",},})
                        -- 运营日志
                        skynet.fork(function()
                            local logData = {
                                guild_land_id = id,
                                guild_land_type = obj:getMapType(),
                            }
                            require("logLib"):writeLog4Gm(buildUid, gLogEvent.guild_land, logData)
                        end)
                    end
                end
            end)
        elseif timerType == "defenderCdTime" then
            local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
            local updatePro = {
                defender = nil,
                defenderCdTime = 0,
            }
            if mapConf.terr_object_type[mapType] then -- 领地建筑
                updatePro.defender = mapUtils.randomTerrDefenders(mapType, subMapType, level)
                updatePro.defenderNum = mapUtils.calcuDefenderNum(updatePro.defender)
                queueLib:backOccupyQueue(svrconf.kid, id) -- 领地建筑守军恢复时, 与占领部队战斗
            else -- 建筑矿, 碉堡
                updatePro.defender = mapUtils.randomDefenders(mapType, subMapType, level)
                updatePro.defenderNum = mapUtils.calcuDefenderNum(updatePro.defender)
            end
            mapCenter:updateMapObjPro(id, nil, updatePro)
        elseif timerType == "annouceTime" then
            mapCenter:updateMapObjPro(id, nil, {annouceTime = 0,})
            skynet.timeout(100, function()
                queueLib:backOccupyCloneQueue(svrconf.kid, id)
            end)
        elseif timerType == "burntime" then
            mapCenter:updateMapObjPro(id, nil, {burntime = 0,})
        else
            gLog.e("mapObjectMgr:timerCallback failed2: ignore", id, timerType)
        end
    else
        gLog.e("mapObjectMgr:timerCallback error: duplicate", id, timerType)
    end
end
--<<<<<<<<<<<<<<<<<<<<<<< 地图对象倒计时相关 <<<<<<<<<<<<<<<<<<<<<<<


-->>>>>>>>>>>>>>>>>>>>>>> 地图对象领地相关 >>>>>>>>>>>>>>>>>>>>>>>
-- 更新领地建筑激活状态
function mapObjectMgr:updateTerrAct(aid, exceptid)
    gLog.d("mapObjectMgr:updateTerrAct", aid)
    local terrs = self.ownAidTerrRef[aid]
    if terrs and next(terrs) then
        local actTerrs = {}	    --所有激活建筑
        local checkInfo = {} 	--已处理的建筑
        ----- 依次递归联盟总部得出激活建筑 -----
        for objid,obj in pairs(terrs) do
            if not checkInfo[objid] and obj:get_field("buildType") == mapConf.guild_build_type.center and obj:get_field("buildFlag") ~= 1 then -- 设置中的不算
                self:updateTerrActLoop(actTerrs, checkInfo, objid, aid)
            end
        end
        for objid,obj in pairs(terrs) do
            local isAct = actTerrs[objid] and true or false
            if exceptid == objid then
                obj:set_field("isAct", isAct)
            else
                if obj:get_field("isAct") ~= isAct then
                    mapCenter:updateMapObjPro(objid, nil, {isAct = isAct,})
                end
            end
        end
    end
end

function mapObjectMgr:updateTerrAttrs(aid,attrs)
    gLog.d("mapObjectMgr:updateTerrAct", aid)
    local terrs = self.ownAidTerrRef[aid]
    if terrs and next(terrs) then
        if attrs["Guild_Manor_Hp"] then
            gLog.d("mapObjectMgr:updateTerrAct2", attrs["Guild_Manor_Hp"])
            for objid,obj in pairs(terrs) do
                self:onGuildMaxHpChange(obj,attrs["Guild_Manor_Hp"],true)
            end
        end
    end
end

-- 递归遍历
function mapObjectMgr:updateTerrActLoop(actTerrs, checkInfo, objid, aid)
    actTerrs[objid] = true
    checkInfo[objid] = true
    -- 四条边接壤
    for _,diff in ipairs(terrConnectDiff) do
        local newobjid = objid + diff
        if self.ownAidTerrRef[aid][newobjid] and not checkInfo[newobjid] then
            self:updateTerrActLoop(actTerrs, checkInfo, newobjid, aid)
        end
    end
end

-- 更新领地建筑激活状态
function mapObjectMgr:isTerrConnect(objid, aid, isAtk)
    if self.ownAidTerrRef[aid] and next(self.ownAidTerrRef[aid]) then
        -- 有领地
        for _,diff in ipairs(terrConnectDiff) do
            local newobjid = objid + diff
            local obj = self.ownAidTerrRef[aid][newobjid]
            if obj and obj:get_field("isAct") then
                return true
            end
        end
        return false, global_code.map_terr_not_connect
    else
        -- 无领地
        if isAtk then
            return true
        end
        local chairmanid = require("guildinterface").get_chairman_id(nil, aid)
        if chairmanid then
            local cityobj = mapCenter.mapObjectMgr:get_player_city(chairmanid)
            if cityobj then
                local terrConnectDiff2 = mapUtils.terrConnectDiff2()
                local x, y, w, h = cityobj:get_range()
                local chairman_chuckcenterid = mapUtils.pos_to_chunck_center_id(x, y)
                if objid == chairman_chuckcenterid then
                    return true
                end
                local chairman_subzone =  mapCenter:get_subzone(x, y)
                for _,diff in ipairs(terrConnectDiff2) do
                    local newobjid = chairman_chuckcenterid + diff
                    local nx, ny = mapUtils.get_coord_xy(newobjid)
                    local arround_subzone =  mapCenter:get_subzone(nx, ny)
                    if chairman_subzone == arround_subzone
                            and objid == newobjid  then
                        return true
                    end
                end
            end
        end
        return false, global_code.map_terr_not_leader_connect
    end
end

-- 联盟是否拥有至少一个领地建筑
function mapObjectMgr:hasTerr(aid)
    if self.ownAidTerrRef[aid] and next(self.ownAidTerrRef[aid]) then
        return true
    end
    return false
end

function mapObjectMgr:getTerrBuildInfo(aid)
    return self.ownAidTerrRef[aid]
end

-- 获取联盟归属的领地建筑数量, eg:ret = {[type][subtype][lv] = num}
function mapObjectMgr:getTerrBuildNum(aid,_maptype)
    local ret, num ,total = {}, 0 , 0
    if self.ownAidTerrRef[aid] then
        for objid,obj in pairs(self.ownAidTerrRef[aid]) do
            local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
            if not ret[mapType] then
                ret[mapType] = {}
            end
            if not ret[mapType][subMapType] then
                ret[mapType][subMapType] = {}
            end
            ret[mapType][subMapType][level] = (ret[mapType][subMapType][level] or 0) + 1
            if mapConf.terr_object_type[_maptype] == mapConf.terr_object_type[mapType] then
                num = num + 1
            end
            total = total + 1
        end
    end
    return ret, num , total
end

-- 获取联盟某类型的领地数量
function  mapObjectMgr:getTerrLnadNumType(aids, _mapType, _subMapType, _level)
    if not aids then
        aids = table.keys(self.ownAidTerrRef)
    end
    local num = 0
    for _, aid in pairs(aids) do
        if self.ownAidTerrRef[aid] then
            for objid,obj in pairs(self.ownAidTerrRef[aid]) do
                local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
                if (not _mapType or mapType == _mapType) and subMapType == _subMapType and level >= _level then
                    num = num + 1
                end
            end
        end
    end
    return num
end

-- 获取联盟归属的领地建筑数量
function mapObjectMgr:getTerrBuildNumType(aid, buildType)
    local num = 0
    if self.ownAidTerrRef[aid] then
        for objid,obj in pairs(self.ownAidTerrRef[aid]) do
            if obj:get_field("buildType") == buildType then
                num = num + 1
            end
        end
    end
    return num
end

-- 获取拥有的建筑数量
function mapObjectMgr:getOwnBuildNumType(uid, mapType, subMapType)
    local num = 0
    if self.ownUidObjRef[uid] then
        for objectid,_ in pairs(self.ownUidObjRef[uid]) do
            local obj = self:get_object(objectid)
            if obj and obj:getMapType() == mapType and obj:getSubMapType() == subMapType then
                num = num + 1
            end
        end
    end
    return num
end

-- 获取联盟成员的资源建筑数量
function mapObjectMgr:getResBuildNum(uids, level)
    local num = 0
    for _, uid in pairs(uids) do
        if self.ownUidObjRef[uid] then
            for objectid,_ in pairs(self.ownUidObjRef[uid]) do
                local obj = self:get_object(objectid)
                if obj and obj:getMapType() == mapConf.object_type.buildmine and obj:get_level() >= level then
                    num = num + 1
                end
            end
        end
    end
    return num
end

-- 联盟信息变化通知更新地图上领地对象信息
function mapObjectMgr:update_guild_terr_info(aid)
    if self.ownAidTerrRef[aid] then
        for objid,obj in pairs(self.ownAidTerrRef[aid]) do
            obj:set_pack(true)
            mapCenter.mapAoiMgr:update_object(obj)
        end
    end
end

-- 2个区域是否连通, 连通则可以迁城
function mapObjectMgr:isZoneConnect(aid, s_zoneid, e_zoneid, check)
    if s_zoneid == e_zoneid then
        return true
    end
    if not check then
        check = {[s_zoneid] = true}
    end
    if self.zoneconnect[s_zoneid] then
        for zoneid,v in pairs(self.zoneconnect[s_zoneid]) do
            if not check[zoneid] then
                check[zoneid] = true
                local ok = false
                for _,objid in pairs(v) do
                    if self.ownAidTerrRef[aid] and self.ownAidTerrRef[aid][objid] and self.ownAidTerrRef[aid][objid]:get_field("isAct") then
                        ok = true
                        break
                    end
                end
                if ok then
                    if zoneid == e_zoneid then
                        return true
                    end
                    if self:isZoneConnect(aid, zoneid, e_zoneid, check) then
                        return true
                    end
                end
            end
        end
    end
end
--<<<<<<<<<<<<<<<<<<<<<<< 地图对象领地相关 <<<<<<<<<<<<<<<<<<<<<<<


-------------------------外地图属性相关begin----------------------------
function mapObjectMgr:getPlayerAttr(uid)
    return self.ownUidAttr[uid] or {}
end

--计算玩家属性
function mapObjectMgr:calPlayerAttr(uid, nosync)
    skynet.fork(function() --为降低登录延迟
        local oldattr = table.clone(self:getPlayerAttr(uid), true)
        local newattr = {}
        if self.ownUidObjRef[uid] and next(self.ownUidObjRef[uid]) then
            for _, objid in pairs(self.ownUidObjRef[uid]) do
                local obj = self:get_object(objid)
                if obj then
                    local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
                    local resource_buildings = get_static_config().resource_buildings
                    if resource_buildings[mapType] and resource_buildings[mapType][subMapType] and resource_buildings[mapType][subMapType][level] then
                        local cfg = resource_buildings[mapType][subMapType][level]
                        if cfg.AdditiveEffect and type(cfg.AdditiveEffect) == "table" then
                            for k, v in pairs(cfg.AdditiveEffect) do
                                newattr[k] = g_cal_attr(k, newattr[k], v)
                            end
                        end
                    end
                end
            end
            --gLog.d("=======mapObjectMgr:calPlayerAttr result", oldattr, newattr)
            if common.is_diff_table(oldattr, newattr) then
                self.ownUidAttr[uid] = self.ownUidAttr[uid] or {}
                self.ownUidAttr[uid] = newattr
                if not nosync then
                    require("gateLib"):sendPlayer(svrconf.kid, uid, "update_mapattr", self.ownUidAttr[uid])
                end
            end
        end
    end)
end
-------------------------外地图属性相关over----------------------------
-------------------------联盟属性相关begin----------------------------
function mapObjectMgr:getGuildAttr(aid)
    return self.ownAidAttr[aid] or {}
end

--计算联盟属性
function mapObjectMgr:calGuildAttr(aid, nosync)
    skynet.fork(function() --为降低登录延迟
        local oldattr = table.clone(self:getGuildAttr(aid), true)
        local newattr = {}
        local boomnum = 0
        if self.ownAidTerrRef[aid] and next(self.ownAidTerrRef[aid]) then
            for objid, obj in pairs(self.ownAidTerrRef[aid]) do
                local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
                local city_attr = get_static_config().city_attr
                local x, y = obj:get_position()
                local nx = math.ceil((x or 0) / 9)
                local ny = math.ceil((y or 0) / 9)
                local xyid = ny * 10000 + nx
                if city_attr[xyid] and city_attr[xyid].Attr and next(city_attr[xyid].Attr) then
                    for k, v in pairs(city_attr[xyid].Attr) do
                        newattr[k] = g_cal_attr(k, newattr[k], v)
                    end
                end
                local area_battle = get_static_config().area_battle
                if area_battle[mapType] and area_battle[mapType][subMapType] and area_battle[mapType][subMapType][level] then
                    boomnum = boomnum + (area_battle[mapType][subMapType][level].BoomValue or 0)
                end
            end
            gLog.d("=======mapObjectMgr:calGuildAttr result", aid, oldattr, newattr, boomnum)
            if common.is_diff_table(oldattr, newattr) or boomnum > 0 then
                self.ownAidAttr[aid] = self.ownAidAttr[aid] or {}
                self.ownAidAttr[aid] = newattr
                guildinterface.update_guild_mapattr(aid, self.ownAidAttr[aid], boomnum, nosync)
            end
        else
            self.ownAidAttr[aid] = {}
            if common.is_diff_table(oldattr, {}) then
                guildinterface.update_guild_mapattr(aid, self.ownAidAttr[aid], boomnum, nosync)
            end
            guildinterface.unrew_guild_boomrewstate_event(aid, boomnum)
        end
    end)
end
-------------------------联盟属性相关over----------------------------

return mapObjectMgr