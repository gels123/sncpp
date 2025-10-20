--[[
	地图服务中心
]]
local skynet = require ("skynet")
local mapConf = require "mapConf"
local svrFunc = require ("svrFunc")
local gLog = require ("newLog")
local mapUtils = require ("mapUtils")
local mapLib = require "mapLib"
local serviceCenterBase = require("serviceCenterBase2")
local mapCenter = class("mapCenter", serviceCenterBase)

-- 构造
function mapCenter:ctor()
	mapCenter.super.ctor(self)
end

-- 初始化
function mapCenter:init(kid)
	gLog.i("==mapCenter:init begin==", kid)
	self.super.init(self, kid)

	local time = skynet.now()
	-- 设置随机种子
	svrFunc.setRandomSeed()

	-------------- 模块创建 --------------
	---- 定时器管理
	--self.mapTimerMgr = require("mapTimerMgr").new()
	---- 地图视野管理
	--self.mapAoiMgr = require("mapAoiMgr").new()
	---- 掩码管理
	--self.mapMaskMgr = require("mapMaskMgr").new()
	---- 玩家管理
	--self.mapPlayerMgr = require("mapPlayerMgr").new()
	---- 地图对象管理
	--self.mapObjectMgr = require("mapObjectMgr").new()
    ---------------- 模块初始化 --------------
    ---- 定时器管理
    --self.mapTimerMgr:init()
	--
    ---- 掩码初始化
    --local cfg = get_static_config().worldmap_globals
    --local w, h = cfg.MapSize[1], cfg.MapSize[2]
	--local curDir = require("lfs").currentdir()
    --self.mapMaskMgr:init(curDir.."/server/map/search/bitmap/EditMapMask.lua", w, h)
    --self.mapMaskMgr:init_area(get_map_config().area, cfg.WidthDivid, cfg.HeightDivid)
    ---- aoi初始化
    --self.mapAoiMgr:init(w, h, mapConf.world_aoi_confs)
    ---- 地图对象初始化
    --self.mapObjectMgr:init()

    gLog.i("==mapCenter:init end==", kid, "cost time=", skynet.now() - time)
	return true
end

-- 初始化完毕, 开始服务
function mapCenter:init_over()
	gLog.i("==mapCenter:init_over begin==")
	-- 以下几个逻辑可能会调用cache服务等, 所以放此处执行
	self.mapObjectMgr:init_over()
	gLog.i("mapCenter:init_over 1")
	self.mapPlayerMgr:init()
	gLog.i("mapCenter:init_over 2")
	self.super.init_over(self)
	self.initOverOk = true
	gLog.i("==mapCenter:init_over end==")
	return true
end

-- 网关开启
function mapCenter:gate_open()
	gLog.i("==mapCenter:gate_open begin==")
	self.super.gate_open(self)
	gLog.i("==mapCenter:gate_open end==")
	return true
end

-- 停止服务, 安全退出
function mapCenter:safe_quit()
	self.super.safe_quit(self)
	if self.mapDB then
		self.mapDB:destroy()
	end
end

function mapCenter:player_login(playerid, plycache)
	gLog.d("mapCenter:player_login", playerid, plycache)
	local mapPlayer = self.mapPlayerMgr:get_player(playerid)
	if mapPlayer then
		mapPlayer:set_player_cache(plycache)
		mapPlayer:set_online(true)
	end
end

function mapCenter:player_offline(playerid)
	local mapPlayer = self.mapPlayerMgr:get_player(playerid)
	if mapPlayer then
		mapPlayer:set_online(nil)
	end
end

function mapCenter:get_player_cityinfo(playerid)
	if not playerid then
		gLog.e("mapCenter:get_player_cityinfo error", playerid)
		return 
	end
	local cityobj = self.mapObjectMgr:get_player_city(playerid)
	return (cityobj and cityobj:pack_message_data()), self.mapObjectMgr:getPlayerAttr(playerid)
end

function mapCenter:get_player_pos(playerid)
	if not playerid then
		gLog.e("mapCenter:get_player_pos error", playerid)
		return
	end
	local cityobj = self.mapObjectMgr:get_player_city(playerid)
	if cityobj then
		return cityobj:get_position()
	end
end

function mapCenter:update_player_infos(playerid, tab)
	--gLog.d("mapCenter:update_player_infos", playerid, tab)
	for field,value in pairs(tab) do
		self:update_player_info(playerid, field, value)
	end
end

function mapCenter:resourceshieldover(playerid, field, value)
	--gLog.i("破盾 resourceshieldover covershieldover1:")
	if field == "resourceshieldover" then
		--gLog.i("破盾 resourceshieldover covershieldover2:")
		if value > svrFunc.systemTime() then
			local buildmines = self:getBuildmines(playerid)
			--	1)正在被敌方攻击（行军中不算）的资源地。
			--2)玩家无法行军到达（因为失去关卡而断路）的资源地。
			local mapPlayer = self.mapPlayerMgr:get_player(playerid)
			local cityobj = self.mapObjectMgr:get_player_city(playerid)
			if buildmines and next(buildmines) then
				for _, obj in ipairs(buildmines) do
					local objid = obj:get_objectid()
					local isBuildMineWar = require("queueLib"):isBuildMineWar(svrconf.kid, playerid,mapPlayer:get_guild_id(),objid)
					if obj:get_field("status") ~= mapConf.build_status.occupying and not isBuildMineWar then
						local fromX,fromY = cityobj:get_position()
						local toX,toY = obj:get_position()
						local canArrive = require("queueLib"):canArrive(svrconf.kid, mapConf.queueType.attackBuildMine,playerid,fromX,fromY,toX,toY,mapPlayer:get_guild_id())
						if canArrive then
							obj:set_field("shieldover",value)
							self.mapTimerMgr:doUpdate(objid, "shieldover", value)
							-- 开罩后取消被侦查
							self:cancelScout(obj, 4034)
							self.mapAoiMgr:update_object(obj)
							obj:asyn_save()
						else
							gLog.w("无法到达的区域，无法开启护盾",playerid, field, value,fromX,fromY,toX,toY)
						end
					else
						gLog.w("无法开启护盾",obj:get_field("status"),isBuildMineWar)
					end
				end
			end

			local msg = {
				resourceshieldover = value,
			}
			require("cacheinterface").raw_update_player_info(svrconf.kid, playerid, msg, true)
		elseif value == 0 then
			--破盾
			--gLog.i("破盾 resourceshieldover covershieldover:")
			--开启护盾期间，对其他玩家的资源地发起战争行为会导致护盾buff被清除，所有资源地的护盾特效消失（对玩家基地、领地等发起战争行为不会）。
			local buildmines = self:getBuildmines(playerid)
			--gLog.i("resourceshieldover covershieldover1:")
			if buildmines and next(buildmines) then
				for _, obj in ipairs(buildmines) do
					local objid = obj:get_objectid()
					obj:set_field("shieldover",value)
					--gLog.i("resourceshieldover covershieldover2:",value)
					self.mapTimerMgr:removeObjTimer(objid, "shieldover")
					self.mapAoiMgr:update_object(obj)
					obj:asyn_save()
				end
			end
		end
	end
end

function mapCenter:update_player_info(playerid, field, value)
	gLog.d("mapCenter:update_player_info", playerid, field, value)
	self:resourceshieldover(playerid,field,value)
	local mapPlayer = self.mapPlayerMgr:get_player(playerid)
	if mapPlayer then
		local bSave = false
		local cityobj = self.mapObjectMgr:get_player_city(playerid)
		local isNotify, oldValue = mapPlayer:update_player_cache(field, value)
		if isNotify then
			-- 一些字段变化时, 需要特殊逻辑、推送
			if cityobj then
				cityobj:set_pack(true)
				local objid = cityobj:get_objectid()
				if field == "shieldover" then --保护罩到期时间
					if value > svrFunc.systemTime() then
						self.mapTimerMgr:doUpdate(objid, field, value)
						-- 开罩后取消被侦查
						if self:cancelScout(cityobj, 4034) then
							bSave = true
						end
					end
				elseif field == "skintime" then
					cityobj:set_field("skintime", value)
					self.mapTimerMgr:doUpdate(objid, field, value)
					bSave = true
				elseif field == "skin" then
					cityobj:set_field("skin", value)
					bSave = true
				elseif field == "guildid" then --联盟改变
					self.mapObjectMgr:onGuildIdChange(playerid, oldValue, tonumber(value) or 0)
					-- 变成同盟友盟取消被侦查
					if value > 0 then
						local scoutInfo = cityobj:get_field("scoutInfo")
						--gLog.d("mapCenter:update_player_info", playerid, field, value, "scoutInfo=", scoutInfo)
						if next(scoutInfo) then
							local uids = table.keys(scoutInfo)
							for _,uid in pairs(uids) do
								if guildinterface.isUnited(value, guildinterface.call_get_player_guildid(uid)) then
									gLog.i("mapCenter:update_player_info cancelScout do", playerid, uid)
									require("gateLib"):sendPlayerEx(svrconf.kid, uid, "cancelScout", objid, 4033)
									bSave = true
								end
							end
							if bSave then
								cityobj:set_field("scoutInfo", scoutInfo)
							end
						end
					end
				elseif field == "offlinetime" or field == "castlelv" or field == "burntime" then --城堡等级、离线时间、燃烧时间
					cityobj:set_field(field, value or 0)
					if field == "burntime" then
						self.mapTimerMgr:doUpdate(objid, field, value)
					end
					bSave = true
				end
				self.mapAoiMgr:update_object(cityobj)
			end
		end
		if bSave then
			cityobj:asyn_save()
		end
	end
end

-- 联盟信息变化通知更新地图上领地对象信息
function mapCenter:update_guild_terr_info(aid)
	gLog.d("mapCenter:update_guild_terr_info", aid)
	if aid and aid > 0 then
		self.mapObjectMgr:update_guild_terr_info(aid)
	end
end

-- 2个区域是否连通, 连通则可以迁城
function mapCenter:isZoneConnect(aid, s_zoneid, e_zoneid)
	gLog.d("mapCenter:isZoneConnect", aid, s_zoneid, e_zoneid)
	if aid and aid > 0 then
		return self.mapObjectMgr:isZoneConnect(aid, s_zoneid, e_zoneid)
	end
end

-- 地图触发取消侦查
function mapCenter:cancelScout(obj, mid, limitUids)
	local scoutInfo = obj:get_field("scoutInfo")
	--gLog.d("mapCenter:cancelScout", obj:get_objectid(), mid, limitUids,scoutInfo)
	if next(scoutInfo) then
		local curTime = svrFunc.systemTime()
		local objid = obj:get_objectid()
		for uid,time in pairs(scoutInfo) do
			if not limitUids or limitUids[uid] or time < curTime then
				gLog.i("mapCenter:cancelScout do", objid, mid, uid)
				scoutInfo[uid] = nil
				require("gateLib"):sendPlayerEx(svrconf.kid, uid, "cancelScout", objid, mid)
			end
		end
		obj:set_field("scoutInfo", scoutInfo)
		gLog.d("mapCenter:cancelScout end", obj:get_objectid(), scoutInfo)
		return true
	end
end

-- 创建玩家城堡
function mapCenter:create_player_city(playerid, plycache, x, y, zoneId, isGm)
	if svrconf.DEBUG then
		gLog.d("mapCenter:create_player_city playerid=", playerid, "plycache=", plycache, "x=", x, "y=", y, "zoneId=", zoneId)
	end
	if not playerid or not plycache then
		gLog.e("mapCenter:create_player_city error1: playerid=", playerid, "plycache=", plycache)
		return
	end
	local cityobj = self.mapObjectMgr:get_player_city(playerid)
	if cityobj then
		if isGm then
			gLog.w("mapCenter:create_player_city gm create: playerid=", playerid)
		else
			gLog.e("mapCenter:create_player_city error2: playerid=", playerid, "plycache=", plycache)
			return cityobj:pack_message_data()
		end
	end
	-- 先创建玩家信息
	local mapPlayer = self.mapPlayerMgr:create_player(playerid)
	mapPlayer:set_player_cache(plycache)
	mapPlayer:set_online(true)
	-- 再创建玩家城堡
	local params = {
		type = mapConf.object_type.playercity,
		subtype = nil,
		x = x,
		y = y,
		playerid = playerid,
		castlelv = mapPlayer:get_castle_level(),
		offlinetime = svrFunc.systemTime(),
		hp = mapUtils:getPlayerCitydurability(mapPlayer:get_walllv()),
		recoverTime = 0,
	}
	-- 随机坐标
	if not params.x or not params.y then
		params.x, params.y = self.mapMaskMgr:random_playerbornpos(zoneId)
	end
	gLog.dump(params, "mapCenter:create_player_city params=", 10)
	if not params.x or not params.y then
		return
	end
	local cityobj = self.mapObjectMgr:create_object(params)
	cityobj._record:asyn_save()
	return cityobj:pack_message_data()
end

function mapCenter:remove_player_city(playerid)
	local cityobj = self.mapObjectMgr:get_player_city(playerid)
	if cityobj then
		require("mapObjInterface").remove_player_city(cityobj)
	end
end

-- 请求地图信息
function mapCenter:reqmapinfo(kid, playerid, x, y, radius, ispost)
	return self.mapAoiMgr:reqmapinfo(kid, playerid, x, y, radius, ispost)
end

function mapCenter:reqmapobjectdetail(objectid, playerid, flag)
	gLog.d("mapCenter:reqmapobjectdetail", objectid, playerid, flag)
	local detail, obj, player_detail, player_obj = nil, nil, nil, nil
	if objectid and objectid > 0 then
		local object = self.mapObjectMgr:get_object(objectid)
		if object then
			detail = object:pack_message_data_detail()
			if flag then
				obj = object:pack_message_data()
			end
		end
	end
	if playerid and playerid > 0 then
		local object = self.mapObjectMgr:get_player_city(playerid)
		if object then
			player_detail = object:pack_message_data_detail()
			if flag then
				player_obj = object:pack_message_data()
			end
		end
	end
	return detail, obj, player_detail, player_obj
end

function mapCenter:getMapObjAttrs(objectid, attrNames)
	local object = self.mapObjectMgr:get_object(objectid)
	if not object then
		gLog.d("mapCenter:getMapObjAttrs1",objectid,attrNames)
		return
	end
	if attrNames then
		local ret = object:get_fields(attrNames)
		if object:getMapType() == mapConf.object_type.playercity then
			local mapPlayer = self.mapPlayerMgr:get_player(object:get_playerid())
			if mapPlayer then
				for _,k in pairs(attrNames) do
					if mapConf.player_field2[k] then
						ret[k] = mapPlayer._playercache and mapPlayer._playercache[k]
					end
				end
			end
		end
		gLog.d("mapCenter:getMapObjAttrs2",objectid,ret)
		return ret
	else
		gLog.d("mapCenter:getMapObjAttrs3",objectid, object:pack_message_data())
		return object:pack_message_data()
	end
end

function mapCenter:getPlayersCityAttrs(plyids, attrNames)
	if type(plyids) ~= "table" then
		return 
	end
	local rets = {}
	for _, plyid in pairs(plyids) do
		local ret
		local object = self.mapObjectMgr:get_player_city(plyid)
		if object then
			if attrNames then
				ret = object:get_fields(attrNames)
				local mapPlayer = self.mapPlayerMgr:get_player(plyid)
				if mapPlayer then
					for _,k in pairs(attrNames) do
						if mapConf.player_field2[k] then
							ret[k] = mapPlayer:get_attr(k)
						end
					end
				end
			else
				ret = object:pack_message_data()
			end
		end
		if ret then
			rets[plyid] = ret
		end
	end
	return rets
end


function mapCenter:updateTerrAttrs(aid,attrs)
	self.mapObjectMgr:updateTerrAttrs(aid,attrs)
end
function mapCenter:getMapObjsInfo(objids)
	local ret = {}
	for k,objectid in pairs(objids) do
		local object = self.mapObjectMgr:get_object(objectid)
		if object then
			ret[objectid] = object:pack_message_data()
		end
	end
	return ret
end
function mapCenter:getMapObjsNotOwner(objids,filterOwner,searchOwner)
	local ret = {}
	local ret2 = {}
	gLog.d("search mapCenter:getMapObjsNotOwner:",objids,filterOwner,searchOwner)
	for k,objectid in ipairs(objids) do
		local object = self.mapObjectMgr:get_object(tonumber(objectid))
		if not filterOwner then
			if object and (not object:get_field("ownUid") or object:get_field("ownUid") <= 0 )  then
				ret[objectid] = object:pack_message_data()
				table.insert(ret2,objectid)
			end
		else
			if object  then
				gLog.d("search object:",objectid,object:get_field("ownUid"))
				if (object:get_field("ownUid") and object:get_field("ownUid") > 0 and searchOwner ~= object:get_field("ownUid")) then
					ret[objectid] = object:pack_message_data()
					table.insert(ret2,objectid)
				elseif (not object:get_field("ownUid") or object:get_field("ownUid") <= 0 ) then
					ret[objectid] = object:pack_message_data()
					table.insert(ret2,objectid)
				end
			end
		end
	end
	return ret,ret2
end


--更新地图对象属性
function mapCenter:updateMapObjPro(objectid, condition, attrUpdates, attrDels)
	if svrconf.DEBUG then
		gLog.d("mapCenter:updateMapObjPro objectid=", objectid, "condition=", condition, "attrUpdates=", attrUpdates, "attrDels=", attrDels)
	end
	local object = self.mapObjectMgr:get_object(objectid)
	if not object then
		gLog.w("mapCenter:updateMapObjPro fail1", objectid)
		return false
	end
	-- 条件
	if condition then
		for k,v in pairs(condition) do
			if object:get_field(k) ~= v then
				gLog.w("mapCenter:updateMapObjPro fail2", objectid)
				return false
			end
		end
	end
	local mapType = object:getMapType()
	local logicAttrs = {}
	local isNotify, isTerrNotify = false, false
	-- 更新属性
	if attrUpdates then
		for k,v in pairs(attrUpdates) do
			local value = object:get_field(k)
			if (type(v) == "table" and not svrFunc.equalTab(v, value)) or (type(v) ~= "table" and v ~= value) then
				if mapConf.moreLogicAttrs[k] then
					logicAttrs[k] = {object:get_field(k), v}
					local withKey = mapConf.moreLogicAttrsWith[k]
					if withKey then
						logicAttrs[withKey] = {object:get_field(withKey), attrUpdates[withKey]}
					end
				end
				object:set_field(k, v)
				if self.mapTimerMgr.timerCfg[mapType] and self.mapTimerMgr.timerCfg[mapType][k] then
					self.mapTimerMgr:doUpdate(objectid, k, v)
				end
				if mapConf.notifyAttrs[k] then
					isNotify = true
				end
				if mapConf.terr_object_type[mapType] and mapConf.notifyTerrAttrs[k] then
					isTerrNotify = true
				end
			end
		end
	end
	-- 删除属性
	if attrDels then
		for _,k in pairs(attrDels) do
			if nil ~= object:get_field(k) then
				if mapConf.moreLogicAttrs[k] then
					logicAttrs[k] = {object:get_field(k), nil}
				end
				object:set_field(k, nil)
				if mapConf.notifyAttrs[k] then
					isNotify = true
				end
				if mapConf.terr_object_type[mapType] and mapConf.notifyTerrAttrs[k] then
					isTerrNotify = true
				end
			end
		end
	end
	-- 一些字段更新后需要执行更多逻辑
	if next(logicAttrs) then
		self.mapObjectMgr:doMoreLogicAttrs(object, logicAttrs)
	end
	object:asyn_save()
	-- 一些字段更新后需要推送给客户端
	if isNotify then
		self.mapAoiMgr:update_object(object)
		if mapConf.own_object_type[mapType] then
			local ownUid = object:get_field("ownUid")
			if ownUid and ownUid > 0 and (mapType == mapConf.object_type.buildmine or mapType == mapConf.object_type.fortress) then
				require("gateLib"):sendMsgToPlayer(svrconf.kid, ownUid, "syncgetbuildmines", {cell = object:pack_message_data(),})
			end
		end
	end
	-- 领地建筑一些字段更新后需要推送给全联盟
	if isTerrNotify then
		local ownAid = object:get_field("ownAid")
		if ownAid and ownAid > 0 then
			require("gateLib"):sendGuildPlayers(svrconf.kid, ownAid, "send2client", "synterrbuildinfo", {cell = object:pack_message_data(),})
		end
	end
	return true
end

--删除地图对象
function mapCenter:deleteMapObj(objectid, condition, more)
	if svrconf.DEBUG then
		gLog.dump(condition, "mapCenter:deleteMapObj objectid="..tostring(objectid), 10)
	end
	local object = self.mapObjectMgr:get_object(objectid)
	if not object then
		gLog.w("mapCenter:deleteMapObj fail1", objectid)
		return false
	end
	if condition then
		for k,v in pairs(condition) do
			if v ~= object:get_field(k) then
				gLog.w("mapCenter:deleteMapObj error", objectid, condition)
				return false
			end
		end
	end
	self.mapObjectMgr:remove_object(object, more)
	return true
end

--移除观察者
function mapCenter:remove_watcher(playerid)
	gLog.i("mapCenter:remove_watcher", playerid)
	self.mapAoiMgr:remove_watcher(playerid)
end

function mapCenter:check_mask(x, y, width, height, exceptid)
	return self.mapMaskMgr:check_mask(x, y, width, height, exceptid)
end

function mapCenter:lock_block(x, y, width, height, exceptid)
	if self.mapMaskMgr:check_mask(x, y, width, height, exceptid) then
		return false
	end
	self.mapMaskMgr:lock_block(x, y, width, height)
	return true
end

function mapCenter:unlock_block(x, y, width, height)
	self.mapMaskMgr:unlock_block(x, y, width, height)
end

function mapCenter:lock_block_random_move(size, x, y, subzoneid)
	if not subzoneid or subzoneid <= 0 then
		if x and x > 0 and y and y > 0 then
			subzoneid = self.mapMaskMgr:get_subzone(x, y)
		end
	end
	if not subzoneid or subzoneid <= 0 then
		gLog.e("mapCenter:lock_block_random_move", size, x, y)
		subzoneid = nil
	end
	gLog.i("mapCenter:lock_block_random_move do=", x, y, "subzoneid=", subzoneid)
	x, y = self.mapMaskMgr:random_playercitypos(subzoneid, size, true)
	gLog.i("mapCenter:lock_block_random_move ok=", x, y, "subzoneid=", subzoneid)
	if not x or not y then
		return false
	end
	self.mapMaskMgr:lock_block(x, y, size, size)
	return true, x, y
end

-- 玩家迁城迁出处理 toServerid=目标服务器ID effect=1击飞特效
function mapCenter:onMoveCityOut(toServerid, playerid, x, y, plycache, movetype, effect, wallinfo)
	if svrconf.kid == toServerid then
		-- 本服迁城
		gLog.i("mapCenter:onMoveCityOut 1=", toServerid, playerid, x, y, movetype, effect)
		-- 自动取消被侦查, 删除原城堡
		local cityobj = self.mapObjectMgr:get_player_city(playerid)
		if cityobj then
			-- 自动取消被侦查
			self:cancelScout(cityobj, 4032)
			-- 删除原城堡
			self.mapObjectMgr:remove_object(cityobj, {effect = effect,})
		else
			gLog.e("mapCenter:onMoveCityOut error", toServerid, playerid, x, y, movetype, effect)
		end
		-- 更新缓存信息
		local mapPlayer = self.mapPlayerMgr:get_player(playerid)
		if not mapPlayer then
			mapPlayer = self.mapPlayerMgr:create_player(playerid)
		end
		if plycache then
			mapPlayer:set_player_cache(plycache)
		end
		-- 创建新城堡
		local walllv = mapPlayer:get_walllv()
		local params = {
			type = mapConf.object_type.playercity,
			subtype = nil,
			x = x,
			y = y,
			playerid = playerid,
			castlelv = mapPlayer:get_castle_level(),
			offlinetime = svrFunc.systemTime(),
			hp = (cityobj and cityobj:get_field("hp")) or (wallinfo and wallinfo.dud) or mapUtils:getPlayerCitydurability(walllv),
			recoverTime = (cityobj and cityobj:get_field("recoverTime")) or (wallinfo and wallinfo.st) or 0,
			landshieldover = cityobj and cityobj:get_field("landshieldover") or 0,
			burntime = cityobj and cityobj:get_field("burntime") or 0
		}
		table.merge(params, cityobj:pack_inherited_attr_data())
		gLog.dump(params, "mapCenter:onMoveCityOut params=", 10)
		cityobj = self.mapObjectMgr:create_object(params)
		cityobj:asyn_save()
		-- 新手换区迁城, 放弃所有归属的建筑矿等
		if movetype == mapConf.move_type.randomzone then
			self:giveUpOwnObjs(playerid, 0)
		end
	else
		-- 跨服迁城
		gLog.i("mapCenter:onMoveCityOut 2=", toServerid, playerid, x, y, movetype, effect)
		-- 删除原城堡
		local cityobj = self.mapObjectMgr:get_player_city(playerid)
		if cityobj then
			self.mapObjectMgr:remove_object(cityobj)
		else
			gLog.e("mapCenter:onMoveCityOut error", toServerid, playerid, x, y, movetype, effect)
		end
		-- 创建新城堡
		mapLib:onMoveCityIn(toServerid, svrconf.kid, playerid, x, y)
		-- 清除缓存信息
		self.mapPlayerMgr:remove_player(playerid)
	end
	return true
end

-- 玩家迁城迁入处理 fromServerid=来源服务器ID
function mapCenter:onMoveCityIn(fromServerid, playerid, x, y)
	gLog.i("mapCenter:onMoveCityIn", fromServerid, playerid, x, y)
	-- 本服迁城迁入/跨服迁城迁入公共处理
	if svrconf.kid ~= fromServerid then
		-- 跨服迁城迁入处理
		-- 删除原城堡
		local cityobj = self.mapObjectMgr:get_player_city(playerid)
		if cityobj then
			self.mapObjectMgr:remove_object(cityobj)
		end
		-- 创建新城堡
		local params = {
			type = mapConf.object_type.playercity,
			subtype = nil,
			x = x,
			y = y,
			playerid = playerid,
		}
		cityobj = self.mapObjectMgr:create_object(params)
		cityobj:asyn_save()
	end
	return true
end

-- 校验创建行军队列
function mapCenter:checkMarch(req, uid, aid)
	gLog.dump(req, "mapCenter:checkMarch req uid="..uid.." aid="..tostring(aid), 10)
	-- 判断免战
	if require("queueLib"):isForbidWar(svrconf.kid, req.queueType) then
		gLog.w("mapCenter:checkMarch error1", uid, req.queueType, req.toId)
		return false, global_code.forbit_war
	end
	-- 某些队列特殊逻辑
	if req.taskID and req.taskID > 0 then
		if (req.queueType == mapConf.queueType.killMonster or req.queueType == mapConf.queueType.explore) then
			-- 雷达任务对象需要生成一只
			local quest_target = get_static_config().quest_target
	        local mType, mLv = quest_target[req.taskID].Wildmonster[1][1], quest_target[req.taskID].Wildmonster[2]
	        if not mType or not mLv then
	        	gLog.w("mapCenter:checkMarch error2", uid, req.queueType, req.toId, "mType=", mType, mLv)
				return false, global_code.error_param
	        end
	        -- 
	        local size, aliveTime, range, hp = 1, 1800, 10, 100
	        if req.queueType == mapConf.queueType.killMonster then
	        	local radar_task = get_static_config().radar_task
				local monster_lv = get_static_config().monster_lv
				size = monster_lv[mType][mLv].Size or 1
				aliveTime = monster_lv[mType][mLv].DisappearTime or 1800
				range = radar_task[req.taskID].Range or 10
			elseif req.queueType == mapConf.queueType.explore then
				local radar_task = get_static_config().radar_task
				local treasure = get_static_config().treasure
				size = treasure[mType][mLv].Size or 1
				aliveTime = treasure[mType][mLv].DisappearTime or 1800
				range = radar_task[req.taskID].Range or 10
				hp = 1
			end
			-- 原坐标被占用, 重新随机一个空地
			if self.mapObjectMgr:get_object(req.toId) then
				local cityobj = self.mapObjectMgr:get_player_city(uid)
				if not cityobj then
					gLog.w("mapCenter:checkMarch error3.1", uid, req.queueType, req.toId, pos)
					return false, global_code.queue_error_find
				end
				local subzoneid = self.mapMaskMgr:get_subzone(cityobj:get_position())
				local pos = self:getSpacePosRange({math.floor(req.toX-range), math.floor(req.toY-range), 2*range, 2*range}, size, size, subzoneid)
				if not pos then
					pos = self:getSpacePosRange({math.floor(req.toX-2*range), math.floor(req.toY-2*range), 4*range, 4*range}, size, size, subzoneid)
				end
				if not pos then
					gLog.w("mapCenter:checkMarch error3.2", uid, req.queueType, req.toId, pos)
					return false, global_code.queue_error_find
				end
				req.toId = mapUtils.get_coord_id(pos[1], pos[2])
				req.toX = pos[1]
				req.toY = pos[2]
			end
			local params = {
				objectid = req.toId,
				type = req.toMapType,
				subtype = mType,
				x = req.toX,
				y = req.toY,
				level = mLv,
				hp = hp,
				ownUid = uid,
				taskID = req.taskID,
				deadTime = svrFunc.systemTime() + aliveTime,
			}
			gLog.dump(params, "mapCenter:checkMarch params=", 10)
			local object = self.mapObjectMgr:create_object(params)
			object:asyn_save()
		end
	end
	-- 地图对象是否存在
	local object = self.mapObjectMgr:get_object(req.toId)
	if not object or object:getMapType() ~= req.toMapType or object:get_field("x") ~= req.toX or object:get_field("y") ~= req.toY then
		gLog.w("mapCenter:checkMarch error4", req.queueType, req.toId, object and object:getMapType(), req.toMapType, object and object:get_field("x"),req.toX , object and object:get_field("y"),req.toY)
		return false, global_code.status_change
	end
	-- 不同队列类型判断
	if req.queueType == mapConf.queueType.collectMine then --采集队列
		-- 是否友盟

	elseif req.queueType == mapConf.queueType.killMonster then
		if mapConf.monster_type_radar[object:getSubMapType()] then
			-- 雷达任务怪, 只能攻击自己的
			local ownUid = object:get_field("ownUid")
			if ownUid and ownUid > 0 and ownUid ~= uid then
				gLog.w("mapCenter:checkMarch error5.1", uid, req.queueType, req.toId, ownUid)
				return false, global_code.error_monster_radar
			end
		else
			-- 普通怪, 判断打怪等级
			local monsterLv = require("gateLib"):callPlayer(svrconf.kid, uid, "getMonsterLv") + 1
			if object:get_level() > monsterLv then
				gLog.w("mapCenter:checkMarch error5.2", uid, req.queueType, req.toId, monsterLv, object:get_level())
				return false, global_code.error_monster_lv
			end
		end
	elseif req.queueType == mapConf.queueType.attackPlayer then
		-- 不能打自己
		if uid == object:get_field("playerid") then
			gLog.w("mapCenter:checkMarch error6.1", uid, req.queueType, req.toId)
			return false, global_code.error_monster_radar
		end
		-- 是否友盟
		if guildinterface.isUnited(aid, guildinterface.call_get_player_guildid(object:get_field("playerid"))) then
			gLog.w("mapCenter:checkMarch error6.2", uid, req.queueType, req.toId)
			return false, global_code.queue_error_friend
		end
		-- 被攻击方是否新手保护, 因为无城墙, 被打无法扣血击飞
		local mapPlayer = self.mapPlayerMgr:get_player(object:get_playerid())
		if (mapPlayer and mapPlayer:get_castle_level() or 0) < 3 then
			gLog.w("mapCenter:checkMarch error6.3", uid, req.queueType, req.toId)
			return false, global_code.player_city_new_hand
		end
		-- [策划说先去掉]被攻击方在自己的生效领地范围内, 无法被攻击
		--local guildid = mapPlayer:get_guild_id()
		--if guildid > 0 then
		--	local w, h = mapUtils.get_obj_size(mapConf.object_type.playercity)
		--	if self:isAreaTerr(svrconf.kid, req.toX, req.toY, w, h, guildid) then
		--		gLog.i("mapCenter:checkMarch error6.4", self:getId(), object:get_playerid(), guildid)
		--		return false, global_code.player_under_protect_terr
		--	end
		--end
	elseif req.queueType == mapConf.queueType.explore then
		if object:getSubMapType() == mapConf.chest_type.radar_npc then
			-- 雷达任务npc, 只能领取自己的
			local ownUid = object:get_field("ownUid")
			if ownUid and ownUid > 0 and ownUid ~= uid then
				gLog.w("mapCenter:checkMarch error7", uid, req.queueType, req.toId, ownUid)
				return false, global_code.error_monster_radar
			end
		end
	elseif req.queueType == mapConf.queueType.attackBuildMine then
		-- 自己的、友盟的、有保护罩的、受到城池保护的建筑矿的, 不能攻打
		-- 有保护罩的不能攻打
		local shieldover = object:get_field("shieldover") or 0
		if shieldover > svrFunc.systemTime() then
			gLog.d("client_request.reqMarch error8.1")
			return false, global_code.error_protect_no_atk
		end
		-- 受到城池保护的建筑矿的不能打
		local groupId = object:get_field("groupId") or 0
		if groupId > 0 then
			local object2 = self.mapObjectMgr:get_object(groupId)
			if object2 and object2:getMapType() == mapConf.object_type.city then
				local ownAid = object2:get_field("ownAid") or 0
				if not (aid and aid > 0 and aid == ownAid) then
					gLog.w("mapCenter:checkMarch error8.3", uid, req.queueType, req.toId, groupId, ownUid, aid, "cityownAid=", ownAid)
					return false, global_code.error_obj_protect_by_city
				end
			end
		end
	elseif req.queueType == mapConf.queueType.helpBuildMine then
		-- 自己的、友盟的才能援防
		local ownUid = object:get_field("ownUid")
		if not (ownUid and ownUid > 0 and (ownUid == uid or guildinterface.isUnited(aid, guildinterface.call_get_player_guildid(ownUid)))) then
			gLog.w("mapCenter:checkMarch error8.4", uid, req.queueType, req.toId, ownUid)
			return false, global_code.queue_help_error_friend
		end
	elseif req.queueType == mapConf.queueType.brigade then
		--
		if not req.buildType or req.buildType <= 0 then
			gLog.w("mapCenter:checkMarch error9.1", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.error_param
		end
		-- 状态判断
		local status = object:get_field("status")
		if not (status == mapConf.build_status.occupied or status == mapConf.build_status.building or status == mapConf.build_status.not_settle) then
			gLog.w("mapCenter:checkMarch error9.2", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.error_build_status
		end
		-- 地块等级判断
		if status == mapConf.build_status.occupied then
			local resourcebuild_num = get_static_config().resourcebuild_num
			if object:get_level() < (resourcebuild_num[req.buildType] and resourcebuild_num[req.buildType].ReqRssLv or 0) then
				gLog.w("mapCenter:checkMarch error9.3", uid, req.queueType, req.toId, object:get_field("status"))
				return false, global_code.error_build_level_limit
			end
		end
		-- 不能改变资源点类型
		local subMapType = object:getSubMapType()
		if subMapType > 0 and subMapType ~= req.buildType then
			gLog.w("mapCenter:checkMarch error9.4", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.error_build_mine_change_type
		end
	elseif req.queueType == mapConf.queueType.helpPlayer then
		-- 不能援助自己、或者敌人
		local playerid = object:get_field("playerid")
		if playerid == uid or not guildinterface.isUnited(aid, guildinterface.call_get_player_guildid(playerid)) then
			gLog.w("mapCenter:checkMarch error10.1", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.error_help_self_enemy
		end
	elseif req.queueType == mapConf.queueType.massBoss then
		if not aid or aid <= 0 then
			gLog.w("mapCenter:checkMarch error11.1", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.error_mass_no_guild
		end
	elseif req.queueType == mapConf.queueType.massCity or req.queueType == mapConf.queueType.attackCity then
		-- 领地相关建筑, 检查宣战时间
		local annouceTime = guildinterface.getAnnounceTime(aid, req.toId) or 0
		if annouceTime <= svrFunc.systemTime() then
			gLog.w("mapCenter:checkMarch error11.2", uid, req.queueType, req.toId, object:get_field("status"), annouceTime)
			return false, global_code.queue_march_has_not_annouce
		end
		-- 是否领地接壤
		if not self:isTerrConnect(req.toId, aid, true) then
			gLog.w("mapCenter:checkMarch error11.3", uid, req.queueType, req.toId, object:get_field("status"))
			return false, global_code.map_terr_not_connect
		end
		-- 攻占新领地, 需检查领地数量
		local ownAid = object:get_field("ownAid") or 0
		if not (aid == ownAid or guildinterface.isUnited(aid, ownAid)) then
			local _,terrNum = self:getTerrBuildNum(aid,object:getMapType())
			local terrMaxNum = (mapConf.terr_object_type[object:getMapType()] == 1 and guildinterface.get_max_city_num(aid)) or (mapConf.terr_object_type[object:getMapType()] == 2 and guildinterface.get_max_terr_num(aid)) or 0
			if (terrNum or 0) + 1 > terrMaxNum then
				gLog.w("mapCenter:checkMarch error11.4", uid, req.queueType, req.toId, object:get_field("status"), terrNum, annouceNum, terrMaxNum)
				return false, global_code.map_terr_limit
			end
		end
	elseif req.queueType == mapConf.queueType.helpCity or req.queueType == mapConf.queueType.massHelpCity then
		-- 检查归属
		if not guildinterface.isUnited(aid, object:get_field("ownAid")) then
			gLog.w("mapCenter:checkMarch error12.1", uid, req.queueType, req.toId, object:get_field("status"), terrNum, terrMaxNum)
			return false, global_code.map_terr_not_belong
		end
		-- 检查宣战状态
		if req.queueType == mapConf.queueType.massHelpCity then
			local annouceTime = object:get_field("annouceTime") or 0
			if annouceTime <= svrFunc.systemTime() then
				gLog.w("mapCenter:checkMarch error12.2", uid, req.queueType, req.toId, annouceTime)
				return false, global_code.queue_march_has_not_be_annouce
			end
		end
	end
	-- 返回创建队列所需数据
	local mapObj = {
		subMapType = object:getSubMapType(),
		level = object:get_field("level") or 0,
		uid = object:get_field("playerid") or 0,
		groupId = object:get_field("groupId"),
		ownUid = object:get_field("ownUid"),
	}
	return true, mapObj
end
--在范围内随机空地
function mapCenter:getSpacePosRange(range, width, height, subzoneid)
	gLog.d("mapCenter:getSpacePosRange", range, width, height, subzoneid)
	return self.mapMaskMgr:random_space_pos(range, width, height, subzoneid)
end

-- 获取子区域
function mapCenter:get_subzone(x, y)
	return self.mapMaskMgr:get_subzone(x, y)
end

-- 获取出生区域城堡数量
function mapCenter:get_bornzone_objnum(subzoneid)
	return self.mapMaskMgr:get_bornzone_objnum(subzoneid)
end

-- 区域是否触及敌人领地
function mapCenter:isAreaEnemyTerr(x, y, w, h, aid)
	local check = {}
	for ix = x, x + w - 1 do
		for iy = y, y + h - 1 do
			local objid = mapUtils.pos_to_chunck_center_id(ix, iy)
			if not check[objid] then
				check[objid] = true
				local object = self.mapObjectMgr:get_object(objid)
				if object and object:get_field("isAct") then
					local ownAid = object:get_field("ownAid") or 0
					if ownAid > 0 and ownAid ~= aid then
						return true
					end
				end
			end
		end
	end
end

-- 区域是否触及己方领地
function mapCenter:isAreaTerr(x, y, w, h, aid)
	local check = {}
	for ix = x, x + w - 1 do
		for iy = y, y + h - 1 do
			local objid = mapUtils.pos_to_chunck_center_id(ix, iy)
			if not check[objid] then
				check[objid] = true
				local object = self.mapObjectMgr:get_object(objid)
				if object and object:get_field("isAct") then
					local ownAid = object:get_field("ownAid") or 0
					if ownAid > 0 and ownAid == aid then
						return true
					end
				end
			end
		end
	end
end

-- 是否拥有其中一个建筑
function mapCenter:isOwnObj(ownUid, objids)
	return self.mapObjectMgr:isOwnObj(ownUid, objids)
end

-- 获取归属的地图对象
function mapCenter:getOwnObjs(ownUid)
	local buildmines = {}
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				local mapType = obj:getMapType()
				if mapType == mapConf.object_type.buildmine or mapType == mapConf.object_type.fortress then
					buildmines[objid] = obj:pack_message_data()
				end
			end
		end
	end
	--gLog.dump(buildmines, "mapCenter:getOwnObjs ownUid="..ownUid, 10)
	return buildmines
end

-- 获取未绑定工程队队列的建筑矿数量
function mapCenter:getBuildmineNoBrigadeNum(ownUid, brigades)
	gLog.d("mapCenter:getBuildmineNoBrigadeNum", ownUid, brigades)
	local num = 0
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				if obj:getMapType() == mapConf.object_type.buildmine and not brigades[objid] then
					num = num + 1
				end
			end
		end
	end
	return num
end

-- 获取归属的地图对象
function mapCenter:getOwnObjIds(ownUid)
	return self.mapObjectMgr:getOwnObjs(ownUid)
end

-- 放弃所有归属的建筑矿等
function mapCenter:giveUpOwnObjs(ownUid, ownAid)
	local objs = self.mapObjectMgr:getOwnObjs(ownUid)
	if objs and next(objs) then
		local queueLib = require("queueLib")
		for objid,_ in pairs(objs) do
			queueLib:giveUpOwnedObj2(svrconf.kid, ownUid, objid, ownAid, true)
		end
	end
end

-- 通知地图对象侦查/取消侦查
function mapCenter:onScout(objid, uid, endTime)
	gLog.d("mapCenter:onScout", objid, uid, endTime)
	if objid and uid then
		local obj = self.mapObjectMgr:get_object(objid)
		if obj and mapConf.scout_object_type[obj:getMapType()] then
			local scoutInfo = obj:get_field("scoutInfo")
			if endTime then
				scoutInfo[uid] = endTime
				obj:set_field("scoutInfo", scoutInfo)
				obj:asyn_save()
			else
				if scoutInfo[uid] then
					scoutInfo[uid] = nil
					obj:set_field("scoutInfo", scoutInfo)
					obj:asyn_save()
				end
			end
			gLog.d("mapCenter:onScout end", objid, scoutInfo)
		end
	end
end

-- 是否领地接壤
function mapCenter:isTerrConnect(objid, aid, isAtk)
	return self.mapObjectMgr:isTerrConnect(objid, aid, isAtk)
end

-- 联盟是否拥有至少一个领地建筑
function mapCenter:hasTerr(aid)
	return self.mapObjectMgr:hasTerr(aid)
end

--#请求设置/取消设置/拆除/取消拆除领地建筑类型
--buildFlag = 1 设置 buildFlag = 2 拆除 buildFlag = 3 放弃
function mapCenter:setTerrBuildType(objid, aid, buildType, buildFlag, uid)
	local obj = self.mapObjectMgr:get_object(objid)
	if not obj or not mapConf.terr_object_type[obj:getMapType()] then
		gLog.d("mapCenter:setTerrBuildType error1", objid, aid, buildType, buildFlag, uid)
		return false, global_code.map_not_annouce_battle
	end
	-- 归属检查
	if obj:get_field("ownAid") ~= aid then
		gLog.d("mapCenter:setTerrBuildType error2", objid, aid, buildType, buildFlag, uid)
		return false, global_code.map_terr_not_belong
	end
	--
	local curTime = svrFunc.systemTime()
	-- 是否非宣战状态
	local annouceTime = obj:get_field("annouceTime") or 0
	if annouceTime > curTime then
		gLog.d("mapCenter:setTerrBuildType error3", objid, aid, buildType, buildFlag, uid)
		return false, global_code.map_annouce_battle
	end
	--
	local curTime = svrFunc.systemTime()
	if buildFlag == 1 then
		if buildType > 0 then -- 设置
			-- 类型判断
			if buildType ~= mapConf.guild_build_type.center then
				gLog.d("mapCenter:setTerrBuildType error4.1", objid, aid, buildType, buildFlag, uid)
				return false, global_code.error_param
			end
			-- 是否放弃等待中或正在读条中
			if (obj:get_field("buildCdTime") or 0) > curTime or (obj:get_field("buildTime") or 0) > 0 then
				gLog.d("mapCenter:setTerrBuildType error4.2", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_give_up_cd
			end
			-- 是否已设置
			if (obj:get_field("buildType") or 0) > 0 then
				gLog.d("mapCenter:setTerrBuildType error4.3", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_terr_have_build_type
			end
			-- 检查建筑数量上限
			local maxNum = guildinterface.get_capital_limit(aid)
			local num = self.mapObjectMgr:getTerrBuildNumType(aid, buildType)
			if num >= maxNum then
				gLog.d("mapCenter:setTerrBuildType error4.4", objid, aid, buildType, buildFlag, uid)
				return false, global_code.guild_build_type_num_limit
			end
			-- 扣除花费
			local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
			--local area_battle = get_static_config().area_battle
			local globals = get_static_config().globals
			local costNum = globals.Hqcost[num + 1] or globals.Hqcost[#globals.Hqcost]
			--local costNum = area_battle[mapType] and area_battle[mapType][subMapType] and area_battle[mapType][subMapType][level] and area_battle[mapType][subMapType][level].Sethqcost or 0
			gLog.d("mapCenter:setTerrBuildType costNum", mapType, subMapType, level, costNum)
			if costNum > 0 then
				local ok, cod2 = guildinterface.update_wheat(aid, -costNum)
				if not ok then
					gLog.d("mapCenter:setTerrBuildType error4.5", objid, aid, buildType, buildFlag, uid)
					return false, cod2 or global_code.alliance_res_not_enough
				end
			end
			local updatePro = {
				buildType = buildType,
				buildFlag = buildFlag,
				buildTime = curTime + (get_static_config().globals.FarmlandSetHqTime or 60),
				buildUid = uid,
				costwheat = costNum,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		else -- 取消设置
			-- 是否正在设置中
			if not (obj:get_field("buildFlag") == buildFlag and (obj:get_field("buildType") or 0) > 0 and (obj:get_field("buildTime") or 0) > 0) then
				gLog.d("mapCenter:setTerrBuildType error4.3", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_terr_no_have_build_type
			end
			local mapType, subMapType, level = obj:getMapType(), obj:getSubMapType(), obj:get_level()
			local area_battle = get_static_config().area_battle
			local costNum = obj:get_field("costwheat") or 0
			--local costNum = area_battle[mapType] and area_battle[mapType][subMapType] and area_battle[mapType][subMapType][level] and area_battle[mapType][subMapType][level].Sethqcost or 0
			if costNum > 0 then
				local ok, cod2 = guildinterface.update_wheat(aid, costNum)
				if not ok then
					gLog.d("mapCenter:setTerrBuildType error4.6", objid, aid, buildType, buildFlag, uid)
					--return false, cod2 or global_code.alliance_res_not_enough
				end
			end
			local updatePro = {
				buildType = mapConf.guild_build_type.init,
				buildFlag = 0,
				buildTime = 0,
				buildCdTime = curTime + 1,
				buildUid = 0,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		end
	elseif buildFlag == 2 then
		if buildType > 0 then -- 拆除
			-- 是否放弃等待中或正在读条中
			if (obj:get_field("buildCdTime") or 0) > curTime or (obj:get_field("buildTime") or 0) > 0 then
				gLog.d("mapCenter:setTerrBuildType error5.1", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_give_up_cd
			end
			-- 是否已设置
			if (obj:get_field("buildType") or 0) <= 0 then
				gLog.d("mapCenter:setTerrBuildType error5.2", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_terr_no_have_build_type
			end
			local updatePro = {
				buildFlag = buildFlag,
				buildTime = curTime + (get_static_config().globals.FarmlandGiveupTime or 60),
				buildUid = uid,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		else -- 取消拆除
			-- 是否已正在拆除
			if not (obj:get_field("buildFlag") == buildFlag and (obj:get_field("buildType") or 0) > 0 and (obj:get_field("buildTime") or 0) > 0) then
				gLog.d("mapCenter:setTerrBuildType error5.3", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_terr_no_have_build_type
			end
			local updatePro = {
				buildFlag = 0,
				buildTime = 0,
				buildCdTime = curTime + 1,
				buildUid = 0,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		end
	elseif buildFlag == 3 then
		if buildType > 0 then -- 放弃
			-- 免战时间不能放弃
			local shieldover = obj:get_field("shieldover")
			if shieldover and shieldover > curTime then
				gLog.d("mapCenter:setTerrBuildType error6.0", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_give_up_shieldover
			end
			-- 是否放弃等待中或正在读条中
			if (obj:get_field("buildTime") or 0) > 0 then
				gLog.d("mapCenter:setTerrBuildType error6.1", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_give_up_cd
			end
			local updatePro = {
				buildFlag = buildFlag,
				buildTime = curTime + (get_static_config().globals.FarmlandGiveupTime or 60),
				buildUid = uid,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		else -- 取消放弃
			-- 是否正在放弃中
			if not (obj:get_field("buildFlag") == buildFlag and (obj:get_field("buildTime") or 0) > 0) then
				gLog.d("mapCenter:setTerrBuildType error6.2", objid, aid, buildType, buildFlag, uid)
				return false, global_code.map_terr_no_have_build_type
			end
			local updatePro = {
				buildFlag = 0,
				buildTime = 0,
				buildCdTime = curTime + 1,
				buildUid = 0,
			}
			self:updateMapObjPro(objid, nil, updatePro)
		end
	else
		return false, global_code.error_param
	end
	return true
end

function mapCenter:getTerrBuildInfo(aid, flag)
	if aid > 0 then
		local objs = self.mapObjectMgr:getTerrBuildInfo(aid)
		if objs then
			local ret = {}
			if flag then
				for _,obj in pairs(objs) do
					ret[obj:get_objectid()] = obj:get_field("status")
				end
			else
				for _,obj in pairs(objs) do
					ret[obj:get_objectid()] = obj:pack_message_data()
				end
			end
			return ret
		end
	end
end
-- 获取拥有的建筑数量
function mapCenter:getOwnBuildNumType(uid, mapType, subMapType)
	return self.mapObjectMgr:getOwnBuildNumType(uid, mapType, subMapType)
end

-- 获取联盟归属的领地建筑数量, eg:ret = {[type][subtype][lv] = num}
function mapCenter:getTerrBuildNum(aid,buildtype)
	return self.mapObjectMgr:getTerrBuildNum(aid,buildtype)
end

-- 获取联盟某类型的领地数量
function mapCenter:getTerrLnadNumType(aids, mapType, subMapType, level)
	return self.mapObjectMgr:getTerrLnadNumType(aids, mapType, subMapType, level)
end

-- pm指定出生区域
function mapCenter:pm_playerbornsubzone(zoneId1, zoneId2, zoneId3, zoneId4, zoneId5, zoneId6)
	return self.mapMaskMgr:pm_playerbornsubzone(zoneId1, zoneId2, zoneId3, zoneId4, zoneId5, zoneId6)
end

-- 领地范围内非同盟玩家城堡击飞随机迁城
function mapCenter:terrKickCastle(uid, aid, objid)
	if not uid or not aid or aid <= 0 or not objid then
		gLog.d("mapCenter:terrKickCastle error1", uid, aid, objid)
		return false, global_code.error_param
	end
	--
	local cityobj = self.mapObjectMgr:get_object(objid)
	if not cityobj or cityobj:getMapType() ~= mapConf.object_type.playercity then
		gLog.w("mapCenter:terrKickCastle error2", uid, aid, objid, cityobj and cityobj.getMapType())
		return false, global_code.error_cant_kick
	end
	--
	local playerid =  cityobj:get_playerid()
	local mapPlayer = self.mapPlayerMgr:get_player(playerid)
	if mapPlayer and mapPlayer:get_guild_id() == aid then
		gLog.w("mapCenter:terrKickCastle error3", uid, aid, objid, "playerid=", playerid, mapPlayer:get_guild_id())
		return false, global_code.error_cant_kick_alliance
	end
	--
	local x, y = cityobj:get_field("x"), cityobj:get_field("y")
	local centerid = mapUtils.pos_to_chunck_center_id(x, y)
	local centerobj = self.mapObjectMgr:get_object(centerid)
	if not centerobj or centerobj:get_field("ownAid") ~= aid then
		gLog.w("mapCenter:terrKickCastle error4", uid, aid, objid, "playerid=", playerid, mapPlayer:get_guild_id())
		return false, global_code.error_cant_kick_no_terr
	end
	gLog.i("mapCenter:terrKickCastle do=", uid, aid, objid, "playerid=", playerid, mapPlayer:get_guild_id())
	local info = guildinterface.call_get_guildinfo(aid, {"name", "shortname"}) or {}
	local mailData = {
		data = {
			x = cityobj:get_field("x"),
			y = cityobj:get_field("y"),
			name = info.name or "",
			shortname = info.shortname or "",
		},
	}
	local gateLib = require("gateLib")
	gateLib:sendPlayerEx(svrconf.kid, playerid, "haveradar", mailData)
	gateLib:sendPlayerEx(svrconf.kid, playerid, "randomMoveCastle")
	return true
end

-- 设置玩家城堡耐久值
function mapCenter:setCastleDurability(objectid, condition, attrUpdates)
	gLog.d("mapCenter:setCastleDurability", objectid, condition, attrUpdates)
	local ok = self:updateMapObjPro(objectid, condition, attrUpdates)
	if not ok then
		return
	end
	local obj = self.mapObjectMgr:get_object(objectid)
	if obj then
		local data = obj:pack_message_data()
		return data.wallst, data.wallet
	end
end

-- 获得大于某等级的建筑矿数量
function mapCenter:getBuildmineNumByLevel(ownUid, level, mtype)
	level = level or 1
	local num = 0
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				local mapType = obj:getMapType()
				if mapType == mapConf.object_type.buildmine and obj:get_level() >= level and (not mtype or mtype == 0 or mtype == obj:getSubMapType()) then
					num = num + 1
				end
			end
		end
	end
	return num
end

function mapCenter:getBuildmines(ownUid)
	local buildmine = {}
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				local mapType = obj:getMapType()
				if mapType == mapConf.object_type.buildmine then
					table.insert(buildmine,obj)
				end
			end
		end
	end
	return buildmine
end

function mapCenter:getBuildmines2(ownUid)
	local buildmine = {}
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				if obj:getMapType() == mapConf.object_type.buildmine then
					buildmine[objid] = true
				end
			end
		end
	end
	return buildmine
end

-- 获取玩家所有城池资源建筑矿
function mapCenter:getCityBuildmines(ownUid)
	local ret = {}
	local objids = self.mapObjectMgr:getOwnObjs(ownUid)
	if objids then
		for _, objid in pairs(objids) do
			local obj = self.mapObjectMgr:get_object(objid)
			if obj then
				if obj:getMapType() == mapConf.object_type.buildmine and (obj:get_field("groupId") or 0) > 0 then
					table.insert(ret, objid)
				end
			end
		end
	end
	return ret
end

--更新奴役
function mapCenter:updateSlave(uid, ownUid, ownTime, cageLv)
	gLog.d("mapCenter:updateSlave", uid, ownUid, ownTime, cageLv)
	if uid and uid > 0 then
		local cityobj = self.mapObjectMgr:get_player_city(uid)
		if cityobj then
			if ownUid and ownUid > 0 and ownTime and ownTime > 0 then
				self:updateMapObjPro(cityobj:get_objectid(), nil, {ownUid = ownUid, ownTime = ownTime, beSlaveCastleLv = cityobj:get_field("castlelv"), beSlaveCageLv = cageLv})
			else
				self:updateMapObjPro(cityobj:get_objectid(), nil, {ownUid = 0, ownTime = 0, beSlaveCastleLv = 0, beSlaveCageLv = 0})
			end
		end
		if ownUid then
			local ownobj = self.mapObjectMgr:get_player_city(ownUid)
			if ownobj then
				if ownTime and ownTime > 0 then
					self:updateMapObjPro(ownobj:get_objectid(), nil, {slaveNum = (ownobj:get_field("slaveNum") or 0) + 1})
				else
					self:updateMapObjPro(ownobj:get_objectid(), nil, {slaveNum = (ownobj:get_field("slaveNum") or 0) - 1})
				end
			end
		end
	end
end

--获取玩家奴隶主uid
function mapCenter:getPlayerOwnUid(uid)
	local object = self.mapObjectMgr:get_player_city(uid)
	if object then
		return object:get_field("ownUid")
	end
end

--pm指令: 打印外地图野怪数量
function mapCenter:dumpMonsterNum()
	self.mapObjectMgr.mapObjMonsterMgr:dumpMonsterNum()
end

--pm指令: 外地图野怪、boss补刷
function mapCenter:doSupplyRefresh(mapType)
	if mapType == mapConf.object_type.monster then
		self.mapObjectMgr.mapObjMonsterMgr:doSupplyRefresh()
	elseif mapType == mapConf.object_type.boss then
		self.mapObjectMgr.mapObjMonsterMgr:doSupplyRefresh()
	end
end

-- 获取联盟成员的资源建筑数量
function mapCenter:getResBuildNum(uids, level)
	return self.mapObjectMgr:getResBuildNum(uids, level)
end

-- 玩家是否为该联盟成员的俘虏
function mapCenter:isGuildSlave(uid, aid)
	gLog.d("=========mapCenter:isGuildSlave", uid, aid)
	local object = self.mapObjectMgr:get_player_city(uid)
	local info = object:get_fields({"ownUid"})
	local ownUid = info.ownUid
	if ownUid and ownUid > 0 then
        local mapPlayer = self.mapPlayerMgr:get_player(ownUid)
		if mapPlayer and mapPlayer:get_guild_id() == aid then
			return true
		end
	end
	return false
end

--更新领地盾时间
function mapCenter:UpdateLandShieldOver(uid, time)
	gLog.d("mapCenter:UpdateLandShieldOver", uid, time)
	if uid and uid > 0 then
		local cityobj = self.mapObjectMgr:get_player_city(uid)
		if cityobj then
			self:updateMapObjPro(cityobj:get_objectid(), nil, {landshieldover = time})
		end
	end
end

-- 根据类型打包地图对象数据
function mapCenter:pack_type_objects(maptypes)
	gLog.d("mapCenter:pack_type_objects maptypes=", maptypes)
	local ret = {}
	for _,v in pairs(maptypes) do
		local mapType, subMapType = v.OpenCity[1], v.OpenCity[2]
		if mapType and subMapType then
			if mapConf.terr_object_type[mapType] then
				local mgr = self.mapObjectMgr.mgrs[mapType]
				if mgr then
					mgr:pack_type_objects(v, mapType, subMapType, ret)
				end
			end
		end
	end
	return ret
end

return mapCenter