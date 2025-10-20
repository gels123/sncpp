--[[
	地图服务对外接口
]]
local skynet = require ("skynet")
local svrAddrMgr = require ("svrAddrMgr")
local mapLib = class("mapLib")

-- 获取服务地址
function mapLib:getAddress(kid)
	return svrAddrMgr.getSvr(svrAddrMgr.mapSvr, kid)
end

-- call调用
function mapLib:call(kid, ...)
	return skynet.call(self:getAddress(kid), "lua", ...)
end

-- send调用
function mapLib:send(kid, ...)
	skynet.send(self:getAddress(kid), "lua", ...)
end

-- 校验创建行军队列
function mapLib:checkMarch(kid, req, uid, aid)
	return self:call(kid, "checkMarch", req, uid, aid)
end

-- 请求地图信息
function mapLib:reqmapinfo(kid, fromServerid, playerid, x, y, radius, ispost)
	return self:call(kid, "reqmapinfo", fromServerid, playerid, x, y, radius, ispost)
end

-- 请求地图对象详细信息
function mapLib:reqmapobjectdetail(kid, objectid, playerid, flag)
	return self:call(kid, "reqmapobjectdetail", objectid, playerid, flag)
end

function mapLib:getMapObjAttrs(kid, objectid, attrNames)
	return self:call(kid, "getMapObjAttrs", objectid, attrNames)
end

function mapLib:getPlayersCityAttrs(kid, plyids, attrNames)
	return self:call(kid, "getPlayersCityAttrs", plyids, attrNames)
end

function mapLib:getOwnBuildNumType(kid,uid, mapType, subMapType)
	return self:call(kid, "getOwnBuildNumType", uid, mapType, subMapType)
end
function mapLib:updateTerrAttrs(kid,aid,attrs)
	return self:call(kid, "updateTerrAttrs", aid,attrs)
end
function mapLib:getMapObjsInfo(kid, objids)
	return self:call(kid, "getMapObjsInfo", objids)
end
function mapLib:getMapObjsNotOwner(kid, objids,filterOwner,searchOwner)
	return self:call(kid, "getMapObjsNotOwner", objids,filterOwner,searchOwner)
end
-- 检测、排查bug
function mapLib:checkMapObjPro(kid, objectid, condition, attrUpdates, attrDels)
	local mapObj = self:getMapObjAttrs(kid, objectid)
	if mapObj then
		if attrUpdates.defender and not next(attrUpdates.defender) and not mapConf.terr_object_type[mapObj.type] then
			gLog.e("mapLib:updateMapObjPro error1", kid, objectid, condition, attrUpdates, attrDels)
		end
		if mapObj.type == mapConf.object_type.monster or mapObj.type == mapConf.object_type.boss then
			if (attrUpdates.subtype and attrUpdates.subtype <= 0) or (attrUpdates.level and attrUpdates.level <= 0) or (attrUpdates.hp and attrUpdates.hp <= 0) then
				gLog.e("mapLib:updateMapObjPro error2.1", kid, objectid, condition, attrUpdates, attrDels, "mapObj=", mapObj)
				return
			end
		elseif mapObj.type == mapConf.object_type.buildmine or mapObj.type == mapConf.object_type.fortress then
			local ownUid = attrUpdates.ownUid or mapObj.ownUid or 0
			local status = attrUpdates.status or mapObj.status
			if ownUid <= 0 then
				if status == mapConf.build_status.init then

				elseif status == mapConf.build_status.occupying then

				elseif status == mapConf.build_status.occupied or status == mapConf.build_status.building or status == mapConf.build_status.settled or status == mapConf.build_status.not_settle then
					gLog.e("mapLib:updateMapObjPro error3.1", kid, objectid, condition, attrUpdates, attrDels, "mapObj=", mapObj)
					attrUpdates.status = mapConf.build_status.init
					attrUpdates.ownUid = 0
					attrUpdates.subtype = 0
					attrUpdates.finish = 0
					attrUpdates.statusStartTime = 0
					attrUpdates.statusEndTime = 0
				end
			else
				if status == mapConf.build_status.init then

				elseif status == mapConf.build_status.occupying then

				elseif status == mapConf.build_status.occupied then
					local subtype = attrUpdates.subtype or mapObj.subtype or 0
					if subtype > 0 then
						gLog.e("mapLib:updateMapObjPro error4.1", kid, objectid, condition, attrUpdates, attrDels, "mapObj=", mapObj)
						attrUpdates.subtype = 0
					end
				elseif status == mapConf.build_status.building or status == mapConf.build_status.settled or status == mapConf.build_status.not_settle then
					local uid = attrUpdates.uid or mapObj.uid or 0
					if uid > 0 then
						gLog.e("mapLib:updateMapObjPro error4.2", kid, objectid, condition, attrUpdates, attrDels, "mapObj=", mapObj)
						attrUpdates.uid = 0
					end
					local subtype = attrUpdates.subtype or mapObj.subtype or 0
					if subtype <= 0 then
						gLog.e("mapLib:updateMapObjPro error4.3", kid, objectid, condition, attrUpdates, attrDels, "mapObj=", mapObj)
						attrUpdates.status = mapConf.build_status.occupied
						attrUpdates.statusStartTime = 0
						attrUpdates.statusEndTime = 0
						attrUpdates.subtype = 0
					end
				end
			end
		elseif mapConf.terr_object_type[mapObj.type] then
			local ownAid = attrUpdates.ownAid or mapObj.ownAid or 0
			if ownAid <= 0 then
				if mapObj.status == mapConf.build_status.init then
				elseif mapObj.status == mapConf.build_status.occupying then
				elseif mapObj.status == mapConf.build_status.occupied then
				elseif mapObj.status == mapConf.build_status.battle then
				end
			else
				if mapObj.status == mapConf.build_status.init then
				elseif mapObj.status == mapConf.build_status.occupying then
				elseif mapObj.status == mapConf.build_status.occupied then
				elseif mapObj.status == mapConf.build_status.battle then
				end
			end
		end
	end
	return true
end

function mapLib:updateMapObjPro(kid, objectid, condition, attrUpdates, attrDels)
	if not self:checkMapObjPro(kid, objectid, condition, attrUpdates, attrDels) then
		return
	end
	return self:call(kid, "updateMapObjPro", objectid, condition, attrUpdates, attrDels)
end

--更新地图对象属性
function mapLib:sendUpdateMapObjPro(kid, objectid, condition, attrUpdates, attrDels)
	if not self:checkMapObjPro(kid, objectid, condition, attrUpdates, attrDels) then
		return
	end
	self:send(kid, "updateMapObjPro", objectid, condition, attrUpdates, attrDels)
end

--删除地图对象
function mapLib:deleteMapObj(kid, objectid, condition, more)
	return self:call(kid, "deleteMapObj", objectid, condition, more)
end

-- 移除观察者
function mapLib:remove_watcher(kid, playerid)
	self:send(kid, "remove_watcher", playerid)
end

-- 创建玩家城堡
function mapLib:create_player_city(kid, playerid, plycache, x, y, zoneId, isGm)
	return self:call(kid, "create_player_city", playerid, plycache, x, y, zoneId, isGm)
end

function mapLib:get_player_cityinfo(kid, playerid)
	return self:call(kid, "get_player_cityinfo", playerid)
end

function mapLib:get_player_pos(kid, playerid)
	return self:call(kid, "get_player_pos", playerid)
end

function mapLib:lock_block(kid, x, y, width, height, exceptid)
	return self:call(kid, "lock_block", x, y, width, height, exceptid)
end

function mapLib:unlock_block(kid, x, y, width, height)
	return self:call(kid, "unlock_block", x, y, width, height)
end

function mapLib:lock_block_random_move(kid, size, x, y, subzoneid)
	return self:call(kid, "lock_block_random_move", size, x, y, subzoneid)
end

-- 玩家迁城迁出处理 toServerid=目标服务器ID effect=1击飞特效
function mapLib:onMoveCityOut(kid, toServerid, playerid, x, y, plycache, movetype, effect, wallinfo)
	return self:call(kid, "onMoveCityOut", toServerid, playerid, x, y, plycache, movetype, effect, wallinfo)
end

-- 玩家迁城迁入处理 fromServerid=来源服务器ID
function mapLib:onMoveCityIn(kid, fromServerid, playerid, x, y)
	return self:call(kid, "onMoveCityIn", fromServerid, playerid, x, y)
end

-- 获取子区域
function mapLib:get_subzone(kid, x, y)
	if x <= 0 or y <= 0 then
		gLog.e("mapLib:get_subzone", kid, x, y)
	end
	return self:call(kid, "get_subzone", x, y)
end

-- 获取区域
function mapLib:get_zone(kid, x, y)
	return math.floor(self:call(kid, "get_subzone", x, y)/100)
end

-- 获取出生区域城堡数量
function mapLib:get_bornzone_objnum(kid, subzoneid)
	return self:call(kid, "get_bornzone_objnum", subzoneid)
end

-- 区域是否触及敌人领地
function mapLib:isAreaEnemyTerr(kid, x, y, w, h, aid)
	return self:call(kid, "isAreaEnemyTerr", x, y, w, h, aid)
end

-- 区域是否触及己方领地
function mapLib:isAreaTerr(kid, x, y, w, h, aid)
	return self:call(kid, "isAreaTerr", x, y, w, h, aid)
end

-- 是否拥有其中一个建筑
function mapLib:isOwnObj(kid, ownUid, objids)
	return self:call(kid, "isOwnObj", ownUid, objids)
end

function mapLib:getOwnObjs(kid, ownUid)
	return self:call(kid, "getOwnObjs", ownUid)
end

function mapLib:getOwnObjIds(kid, ownUid)
	return self:call(kid, "getOwnObjIds", ownUid)
end

function mapLib:getBuildmineNoBrigadeNum(kid, ownUid, brigades)
	return self:call(kid, "getBuildmineNoBrigadeNum", ownUid, brigades)
end

function mapLib:getBuildmines2(kid, ownUid)
	return self:call(kid, "getBuildmines2", ownUid)
end

-- 通知地图对象侦查
function mapLib:onScout(kid, objid, uid, endTime)
	self:send(kid, "onScout", objid, uid, endTime)
end

-- 是否领地接壤
function mapLib:isTerrConnect(kid, objid, aid, isAtk)
	return self:call(kid, "isTerrConnect", objid, aid, isAtk)
end

-- 联盟是否拥有至少一个领地建筑
function mapLib:hasTerr(kid, aid)
	return self:call(kid, "hasTerr", aid)
end

--#请求设置/取消设置/拆除/取消拆除领地建筑类型
function mapLib:setTerrBuildType(kid, objid, aid, buildType, buildFlag, uid)
	return self:call(kid, "setTerrBuildType", objid, aid, buildType, buildFlag, uid)
end

function mapLib:getTerrBuildInfo(kid, aid, flag)
	return self:call(kid, "getTerrBuildInfo", aid, flag)
end

-- 获取联盟归属的领地建筑数量, eg:ret = {[type][subtype][lv] = num}
function mapLib:getTerrBuildNum(kid, aid,buildtype)
	return self:call(kid, "getTerrBuildNum", aid,buildtype)
end

-- 获取联盟某类型的领地数量
function mapLib:getTerrLnadNumType(kid, aids, mapType, subMapType, level)
	return self:call(kid, "getTerrLnadNumType", aids, mapType, subMapType, level)
end

-- pm指定出生区域
function mapLib:pm_playerbornsubzone(kid, zoneId1, zoneId2, zoneId3, zoneId4, zoneId5, zoneId6)
	return self:call(kid, "pm_playerbornsubzone", zoneId1, zoneId2, zoneId3, zoneId4, zoneId5, zoneId6)
end

-- 领地范围内非同盟玩家城堡击飞随机迁城
function mapLib:terrKickCastle(kid, uid, aid, objid)
	return self:call(kid, "terrKickCastle", uid, aid, objid)
end

-- 设置玩家城堡耐久值
function mapLib:setCastleDurability(kid, objectid, condition, attrUpdates)
	return self:call(kid, "setCastleDurability", objectid, condition, attrUpdates)
end

--获得大于某等级的建筑矿数量
function mapLib:getBuildmineNumByLevel(kid, ownUid, level, mtype)
	return self:call(kid, "getBuildmineNumByLevel", ownUid, level, mtype)
end

function mapLib:check_mask(kid, x, y, width, height)
	return self:call(kid, "check_mask", x, y, width, height)
end

--更新奴役
function mapLib:updateSlave(kid, uid, ownUid, ownTime, cageLv)
	self:send(kid, "updateSlave", uid, ownUid, ownTime, cageLv)
end

--pm指令: 打印外地图野怪数量
function mapLib:dumpMonsterNum(kid)
	self:send(kid, "dumpMonsterNum")
end

-- 获取联盟成员的资源建筑数量
function mapLib:getResBuildNum(kid, uids, level)
	return self:call(kid, "getResBuildNum", uids, level)
end

-- 玩家是否为该联盟成员的俘虏
function mapLib:isGuildSlave(kid, uid, aid)
	return self:call(kid, "isGuildSlave", uid, aid)
end

--更新领地盾时间
function mapLib:UpdateLandShieldOver(kid, uid, time)
	self:send(kid, "UpdateLandShieldOver", uid, time)
end

return mapLib