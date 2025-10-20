--[[
	aoi视野服务中心
--]]
local skynet = require("skynet")
local serviceCenterBase = require("serviceCenterBase2")
local aoiCenter = class("aoiCenter", serviceCenterBase)

-- 构造
function aoiCenter:ctor()
    aoiCenter.super.ctor(self)

    -- aoi列表
    self.aois = {}
    for mapId,v in pairs(gMapAoi) do
        if not self.aois[mapId] then
            self.aois[mapId] = {}
        end
        for lv,vv in pairs(v.aois) do
            self.aois[mapId][lv] = require("aoi-simple").new(v.width, v.height, vv.cell, vv.range)
        end
    end
end

-- 初始化
function aoiCenter:init(kid)
    gLog.i("==aoiCenter:init begin==", kid)
    aoiCenter.super.init(self, kid)

    -- 计时器管理器
    self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)

    gLog.i("==aoiCenter:init end==", kid)
    return true
end

--- 添加对象
--@layer 0=普通对象(被观察者) 1=怪物对象(观察者&被观察者) 2=玩家对象(观察者&被观察者) 3=玩家对象(观察者)
function aoiCenter:add(mapId, lv, id, pos, layer)
    return self.aois[mapId][lv]:add(id, pos, layer)
    --local aoiCenter = require("aoiCenter"):shareInstance()
    --if not aoiCenter.aoi then
    --    aoiCenter.aoi = require("aoi-simple").new(1000, 1000, 10, 1)
    --end
    --local obj = {id = 101, pos = {5, 5}, layer = 2}
    --local enter, leave = self.aois[mapId][lv]:add(obj.id, obj.pos, obj.layer)
    --gLog.i("111111111111111111111111 enter=", table2string(enter), "leave=", table2string(leave))
    --local obj = {id = 102, pos = {6, 6}, layer = 2}
    --local enter, leave = aoiCenter.aoi:add(obj.id, obj.pos, obj.layer)
    --gLog.i("222222222222222222222222 enter=", table2string(enter), "leave=", table2string(leave))
    --local obj = {id = 103, pos = {7, 7}, layer = 2}
    --local enter, leave = aoiCenter.aoi:add(obj.id, obj.pos, obj.layer)
    --gLog.i("333333333333333333333333 enter=", table2string(enter), "leave=", table2string(leave))
    --local obj = {id = 104, pos = {8, 8}, layer = 3}
    --local enter, leave = aoiCenter.aoi:add(obj.id, obj.pos, obj.layer)
    --local enter, leave = aoiCenter.aoi:update(103, 69, 69)
    --gLog.i("333333333333333333333333 enter=", table2string(enter), "leave=", table2string(leave))
    --local ret = aoiCenter.aoi:get_visible(104)
    --gLog.dump(ret, "44444444444444444444444")
end

-- 计时器回调
function aoiCenter:timerCallback(data)
    if dbconf.DEBUG then
        gLog.d("aoiCenter:timerCallback data=", table2string(data))
    end
    --local id, timerType = data.id, data.timerType
    --if self.timerMgr:hasTimer(id, timerType) then
    --    if timerType == 0 then
    --        self.aoiMgr:delCachePlayer(id)
    --    elseif timerType == 1 then
    --        self.aoiMgr:delCacheAlliance(id)
    --    end
    --    --gLog.dump(self.aoiMgr, "aoiCenter:timerCallback aoiMgr=")
    --end
end

return aoiCenter
