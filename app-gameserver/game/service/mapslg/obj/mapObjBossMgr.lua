--[[
-- 地图boss(精英怪)刷新和管理
--]]
local skynet = require "skynet"
local skynetenv = require "skynetenv"
local mapConf = require "mapConf"
local Random = require "random"
local mapUtils = require "mapUtils"
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjBossMgr = class("mapObjBossMgr", mapRefreshMgr)
local mapCenter = require("mapCenter"):shareInstance()

function mapObjBossMgr:ctor()
    self.super.ctor(self)

    -- 区域地图对象关联
    self.chunckObjs = {}

    -- 刷新配置
    self.refreshPool = {}

    -- 需要刷新的类型
    self.refreshTypes = {
        [mapConf.boss_type.auto_refresh] = true,
    }

    --
    self.lastLv = 1
end

-- override
function mapObjBossMgr:init()
    gLog.d("mapObjBossMgr:init")
    mapObjBossMgr.super.init(self)

    -- 刷新配置
    self:refresh_boss_pool()
end

-- override
function mapObjBossMgr:init_over()
    self:doSupplyRefresh(true)
end

-- 获取补刷计时器间隔
function mapObjBossMgr:getSupplyTimerInterval()
    local reftime = get_static_config().worldmap_globals.MonsterFullTime
    return Random.Get(reftime[1], reftime[2])
end

-- 获取重刷计时器间隔
function mapObjBossMgr:getResetTimerInterval()
    return get_static_config().worldmap_globals.MonsterClearTime
end

-- 执行补刷
function mapObjBossMgr:doSupplyRefresh(isInit)
    gLog.i("mapObjBossMgr:doSupplyRefresh enter")
    local sq = mapCenter:getSq("mapObjBossMgr")
    sq(function ()
        gLog.i("==mapObjBossMgr:doSupplyRefresh begin==")
        for chunckx=1,mapConf.map_block_line,1 do
            for chuncky=1,mapConf.map_block_line,1 do
                xpcall(function ()
                    local chunckid = mapUtils.get_chunck_id2(chunckx, chuncky)
                    self:refresh_chunck_monster(chunckid)
                    if not isInit then
                        skynet.sleep(svrconf.DEBUG and 0 or 1)
                    end
                end, svrFunc.exception)
            end
        end
        gLog.i("==mapObjBossMgr:doSupplyRefresh end==")
    end)
end

-- 执行重刷
function mapObjBossMgr:doResetRefresh()
    gLog.i("mapObjBossMgr:doResetRefresh enter")
    local sq = mapCenter:getSq("mapObjBossMgr")
    sq(function ()
        gLog.i("==mapObjBossMgr:doResetRefresh begin==")
        -- 刷新配置
        self:refresh_boss_pool()

        local ids = {}
        for chunckx=1,mapConf.map_block_line,1 do
            for chuncky=1,mapConf.map_block_line,1 do
                local chunckid = mapUtils.get_chunck_id2(chunckx, chuncky)
                table.insert(ids, chunckid)
            end
        end
        --随机打乱
        ids = Random.GetSets(ids)
        while(#ids > 0) do
            local chunckid = table.remove(ids)
            if not chunckid then
                break
            end
            xpcall(function ()
                self:reset_chunck(chunckid)
            end, svrFunc.exception)
            skynet.sleep(svrconf.DEBUG and 0 or 1)
        end
        gLog.i("==mapObjBossMgr:doResetRefresh end==")
    end)
end

--重刷区域
function mapObjBossMgr:reset_chunck(chunckid)
    local area = get_static_config().area
    local chunckLv = area[chunckid] and area[chunckid].Level --地块等级
    if not chunckLv then
        chunckLv = self.lastLv
    end
    if self.refreshPool[chunckLv] then
        self.lastLv = chunckLv
        for subMapType,v in pairs(self.refreshPool[chunckLv]) do
            local temp = self:get_chunck_objs(chunckid, subMapType)
            local count = table.nums(temp)
            if count > 0 then
                self:remove_boss(chunckid, subMapType, count)
            end
        end
        self:refresh_chunck_monster(chunckid)
    end
end

--刷新怪物池
function mapObjBossMgr:refresh_boss_pool()
    self.refreshPool = {}
    local opentime = skynetenv.get_open_time()
    local day = require "timext".past_day(opentime)
    if day < 1 then
        day = 1
    end
    gLog.d("mapObjBossMgr:refresh_boss_pool day=", day)
    local monster_refresh_day = get_map_config().monster_refresh_day
    local monster_rally_refresh = get_map_config().monster_rally_refresh
    local monster_rally = get_map_config().monster_rally
    for chunckLv,v in pairs(monster_rally_refresh) do
        for subMapType,cfg in pairs(v) do
            if not self.refreshPool[chunckLv] then
                self.refreshPool[chunckLv] = {}
            end
            if not self.refreshPool[chunckLv][subMapType] then
                self.refreshPool[chunckLv][subMapType] = {
                    num = cfg.Num or 1,
                    totalRate = 0,
                    random = {},
                }
            end
            for i=#monster_refresh_day, 1, -1 do
                local dcfg = monster_refresh_day[i]
                if dcfg.monster_type == 4 and day >= dcfg.day then
                    local totalRate = 0
                    local maxlv = dcfg.monster_lv
                    gLog.d("=mapObjBossMgr:refresh_boss_pool xx chunckLv=", chunckLv, "v=", v, "dcfg=", dcfg, "maxlv=", maxlv)
                    for lv = 1, maxlv do
                        if monster_rally[subMapType] and monster_rally[subMapType][lv] then
                            local key = "Lv" .. lv
                            totalRate = totalRate + (cfg[key] or 0)
                        else
                            break
                        end
                    end
                    self.refreshPool[chunckLv][subMapType].totalRate = totalRate
                    for lv = 1, maxlv do
                        if monster_rally[subMapType] and monster_rally[subMapType][lv] then
                            local key = "Lv" .. lv
                            local rate = (cfg[key] or 0)
                            if rate > 0 then
                                table.insert(self.refreshPool[chunckLv][subMapType].random, {lv = lv, rate = rate})
                            end
                        else
                            break
                        end
                    end
                    break
                end
            end
        end
    end
    gLog.dump(self.refreshPool, "mapObjBossMgr:refresh_boss_pool refreshPool=", 10)
end

function mapObjBossMgr:get_chunck_objs(chunckid, subtype)
    return self.chunckObjs[chunckid] and self.chunckObjs[chunckid][subtype] or {}
end

--刷新区域内怪物
function mapObjBossMgr:refresh_chunck_monster(chunckid)
    local area = get_static_config().area
    if area[chunckid] and area[chunckid].TerrBuild and mapConf.terr_no_monster[area[chunckid].TerrBuild.Type] then -- 小城、大城等的联盟领地格内不刷新野怪和集结野怪
        return
    end
    local flag = (not area[chunckid] or area[chunckid].SubZone == 999) --档格地块
    local chunckLv = area[chunckid] and area[chunckid].Level --地块等级
    if not chunckLv then
        chunckLv = self.lastLv
    end
    if self.refreshPool[chunckLv] then
        self.lastLv = chunckLv
        for subMapType,v in pairs(self.refreshPool[chunckLv]) do
            if self.refreshPool[chunckLv][subMapType] then
                local temp = self:get_chunck_objs(chunckid, subMapType)
                local count = table.nums(temp)
                local cfgNum = self.refreshPool[chunckLv][subMapType].num
                -- gLog.d("mapObjBossMgr:refresh_chunck_monster chunckid=", chunckid, "subMapType=", subMapType, "cfgNum=", cfgNum, "count=", count)
                if cfgNum > count then
                    --需求数量大于当前数量  添加活物
                    self:born_boss(chunckLv, subMapType, chunckid, cfgNum - count, flag)
                elseif count > cfgNum then
                    --当前数量大于需求数量  删除活物
                    self:remove_boss(chunckid, subMapType, count - cfgNum)
                end
            end
        end
    end
end

--生成随机怪物
function mapObjBossMgr:born_boss(chunckLv, subMapType, chunckid, num, flag)
    local refreshCfg = self.refreshPool[chunckLv] and self.refreshPool[chunckLv][subMapType]
    if refreshCfg and refreshCfg.totalRate > 0 then
        local k,v = svrFunc.getRandomIndex(refreshCfg.random, "rate", refreshCfg.totalRate)
        if not v then
            gLog.e("mapObjBossMgr:born_boss error1", refreshCfg)
            return
        end
        local cfg = get_static_config().monster_rally[subMapType][v.lv]
        if not cfg then
            gLog.e("mapObjBossMgr:born_boss error2", subMapType, chunckid, v.lv)
            return
        end
        local w, h = mapUtils.get_obj_size(mapConf.object_type.boss)
        local bnum = num
        while bnum > 0 do
            local pos = mapCenter.mapMaskMgr:random_spacepos_by_chunckid(chunckid, w, h)
            if not pos or not pos[1] or not pos[2] then --该区域都没有位置了 退出
                if flag then
                    gLog.w("mapObjBossMgr:born_boss error3", subMapType, chunckid, v.lv)
                else
                    gLog.w("mapObjBossMgr:born_boss error4", subMapType, chunckid, v.lv, num)
                end
                break
            end
            local x, y = pos[1], pos[2]
            local object = require("mapObjInterface").create_boss(cfg, x, y)
            if not object then
                gLog.e("mapObjBossMgr:born_boss error5", subMapType, chunckid, v.lv)
            end
            bnum = bnum - 1
        end
    end
end

function mapObjBossMgr:remove_boss(chunckid, subMapType, num)
    if num <= 0 then
        return
    end
    local removeobjmap = {}
    local n = num
    local temp = self:get_chunck_objs(chunckid, subMapType)
    if temp then
        for objectid, _  in pairs(temp) do
            local object = mapCenter.mapObjectMgr:get_object(objectid)
            if object and object:canRemove() then
                removeobjmap[objectid] = object
                n = n - 1
            else
                gLog.e("mapObjBossMgr:remove_boss error", chunckid, subMapType, num, "objectid=", objectid)
                temp[objectid] = nil
            end
            if n <= 0 then
                break
            end
        end
    end
    --执行删除
    for _,object in pairs(removeobjmap) do
        mapCenter.mapObjectMgr:remove_object(object)
    end
end

-- 增加对象
function mapObjBossMgr:add_object(obj)
    self.super.add_object(self, obj)

    -- 更新区块地图对象关联
    local x, y = obj:get_position()
    local chunckid = mapUtils.get_chunck_id(x, y)
    local subtype = obj:getSubMapType()
    -- gLog.d("mapObjBossMgr:add_object x=", x, "y=", y, "chunckid=", chunckid, "type=", obj:getMapType(), "subtype=", subtype)
    if not self.chunckObjs[chunckid] then
        self.chunckObjs[chunckid] = {}
    end
    if not self.chunckObjs[chunckid][subtype] then
        self.chunckObjs[chunckid][subtype] = {}
    end
    if not self.chunckObjs[chunckid][subtype] then
        self.chunckObjs[chunckid][subtype] = {}
    end
    self.chunckObjs[chunckid][subtype][obj:get_objectid()] = obj

    -- for debug
    -- local temp = self:get_chunck_objs(chunckid, subtype)
    -- gLog.d("mapObjBossMgr:add_object end=", "chunckid=", chunckid, "type=", obj:getMapType(), "subtype=", subtype, table.nums(temp))
end

-- 删除对象
function mapObjBossMgr:remove_object(obj)
    self.super.remove_object(self, obj)

    -- 更新区域地图对象关联
    local x, y = obj:get_position()
    local chunckid = mapUtils.get_chunck_id(x, y)
    local subtype = obj:getSubMapType()
    if self.chunckObjs[chunckid] and self.chunckObjs[chunckid][subtype] then
        self.chunckObjs[chunckid][subtype][obj:get_objectid()] = nil
    end
end

return mapObjBossMgr
