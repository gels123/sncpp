--[[
-- 地图玩家城堡对象管理
--]]
local skynet = require "skynet"
local mapCenter = require("mapCenter"):shareInstance()
local guildinterface = require "guildinterface"
local queueLib = require "queueLib"
local mapRefreshMgr = require "mapRefreshMgr"
local mapObjPlayerCityMgr = class("mapObjPlayerCityMgr", mapRefreshMgr)

function mapObjPlayerCityMgr:ctor()
	self.super.ctor(self)
	
	-- 玩家城堡关联
	self.playerCitys = {}
end

-- override 初始化
function mapObjPlayerCityMgr:init()
	self.supplyTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onSupplyTimerCallback), svrFunc.getWeehoursUTC() + 86400)
end

-- 增加对象
function mapObjPlayerCityMgr:add_object(obj)
	self.super.add_object(self, obj)

	-- 更新玩家城堡关联
	self.playerCitys[obj:get_playerid()] = obj
	--gLog.i("mapObjPlayerCityMgr:add_object",obj:get_objectid(),obj:get_playerid())
	--
end

-- 删除对象
function mapObjPlayerCityMgr:remove_object(obj)
	self.super.remove_object(self, obj)

	-- 更新玩家城堡关联
	self.playerCitys[obj:get_playerid()] = nil
	--gLog.i("mapObjPlayerCityMgr:remove_object",obj:get_objectid(),obj:get_playerid())
end

-- 获取玩家城堡
function mapObjPlayerCityMgr:get_player_city(playerid)
	return self.playerCitys[playerid]
end

-- 获取所有玩家城堡
function mapObjPlayerCityMgr:get_all_city()
	return self.playerCitys
end

-- 废号移除计时器回调
function mapObjPlayerCityMgr:onSupplyTimerCallback()
	self.supplyTimerId = nil
	skynet.fork(self.doSupplyRefresh, self)
	local time = svrFunc.getWeehoursUTC() + 86400
	gLog.d("mapRefreshMgr:onSupplyTimerCallback", svrFunc.getWeehoursUTC(), time)
	self.supplyTimerId = mapCenter.mapTimerMgr:addTimer(handler(self, self.onSupplyTimerCallback), time)
end

-- 执行废号移除
function mapObjPlayerCityMgr:doSupplyRefresh()
	gLog.i("mapObjPlayerCityMgr:doSupplyRefresh begin")
	local curTime = svrFunc.systemTime()
	local inactivity = get_static_config().inactivity
	local gateLib = require("gateLib")
	for k,v in ipairs(inactivity) do
		if v.Level and v.Time then
			local lv0 = (k>=2 and inactivity[k-1].Level) or -1
			local time = curTime - v.Time
			local sql = string.format("select playerid, offlinetime from playercityobject where castlelv > %d and castlelv <= %d and offlinetime <= %d limit 1000", lv0, v.Level, time)
			gLog.d("mapObjPlayerCityMgr:doSupplyRefresh sql=", sql)
			local ret = mapCenter.mapDB:syn_query_sql(sql)
			gLog.d("mapObjPlayerCityMgr:doSupplyRefresh ret=", ret)
			if ret and ret[1] then
				for k,v in pairs(ret) do
					if v.playerid and v.offlinetime then
						if v.offlinetime <= 0 then -- 异常处理
							gLog.i("mapObjPlayerCityMgr:doSupplyRefresh do1", v.playerid)
							local cityobj = self:get_player_city(v.playerid)
							if cityobj then
								cityobj:set_field("offlinetime", curTime)
								cityobj._record:asyn_save()
							end
						else --废号移除
							if gateLib:callPlayer(svrconf.kid, v.playerid, "is_online") or guildinterface.get_chairman_id(v.playerid) == v.playerid then
								-- 在线或盟主不处理
								gLog.i("mapObjPlayerCityMgr:doSupplyRefresh do2.1", v.playerid)
								local sql = string.format("update playercityobject set offlinetime='%d' where playerid='%d'", curTime, v.playerid)
								local ret2 = mapCenter.mapDB:syn_query_sql(sql)
								if not ret2 or ret2.badresult or ret2.err then
									gLog.e("mapObjPlayerCityMgr:doSupplyRefresh error", ret)
								end
								-- 通知玩家废号移除
								--require("gateLib"):sendPlayerEx(svrconf.kid, v.playerid, "setWashout", true)
							else
								-- 执行废号移除
								gLog.i("mapObjPlayerCityMgr:doSupplyRefresh do2.2", v.playerid)
								local cityobj = self:get_player_city(v.playerid)
								if cityobj then
									-- 自动取消被侦查
									mapCenter:cancelScout(cityobj, 4032)
									-- 自动放弃所有资源点
									local aid = guildinterface.call_get_player_guildid(v.playerid) or 0
									mapCenter:giveUpOwnObjs(v.playerid, aid)
									-- 自动退出联盟
									guildinterface.leave_guild(v.playerid)
									-- 秒遣返所有队列
									queueLib:backAllQueue(svrconf.kid, v.playerid)
									-- 删除原城堡
									mapCenter.mapObjectMgr:remove_object(cityobj)
									-- 通知玩家废号移除
									require("gateLib"):sendPlayerEx(svrconf.kid, v.playerid, "setWashout", true)
								end
							end
						end
					end
					skynet.sleep(svrconf.DEBUG and 0 or 1)
				end
			end
			skynet.sleep(svrconf.DEBUG and 0 or 500)
		end
	end
	gLog.i("mapObjPlayerCityMgr:doSupplyRefresh end")
end

return mapObjPlayerCityMgr
