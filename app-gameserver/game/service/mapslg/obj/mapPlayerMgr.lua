--[[
	玩家数据缓存管理
--]]
local skynet = require "skynet"
local cacheinterface = require "cacheinterface"
local mapPlayerC = require "mapPlayer"
local mapConf = require "mapConf"
local config = require "config"
local clusterext = require "clusterext"
local interaction = require "interaction"
local mapCenter = require("mapCenter"):shareInstance()
local mapPlayerMgr = class("mapPlayerMgr")

function mapPlayerMgr:ctor()
	self._playerlist = {} 			--地图上玩家列表
	self._citynum = 0 				--地图主城数量
	self._warning_count = nil 		--地图主城报警
end

--加载玩家数据缓存
function mapPlayerMgr:init()
	gLog.i("mapPlayerMgr:init begin")
	local playerCitys = mapCenter.mapObjectMgr.mapObjPlayerCityMgr:get_all_city()
	local caches = cacheinterface.call_get_player_info(table.keys(playerCitys), mapConf.player_field)
	--gLog.d("==mapPlayerMgr:init caches=", caches)
	for playerid,cityobj in pairs(playerCitys) do
		self._playerlist[playerid] = mapPlayerC.new(playerid)
		self._playerlist[playerid]:set_player_cache(caches[playerid])
		self._citynum = self._citynum + 1
		--异常处理
		local save = false
		if cityobj:get_field("castlelv") ~= caches[playerid].castlelv then
			cityobj:set_field("castlelv", caches[playerid].castlelv or 0)
			save = true
		end
		if cityobj:get_field("offlinetime") ~= caches[playerid].offlinetime then
			cityobj:set_field("offlinetime", caches[playerid].offlinetime or 0)
			save = true
		end
		if save then
			cityobj:asyn_save()
		end
	end
	gLog.i("mapPlayerMgr:init end", self._citynum)
end

function mapPlayerMgr:get_player(playerid)
	return self._playerlist[playerid]
end

function mapPlayerMgr:remove_player(playerid)
	if self._playerlist[playerid] then
		self._playerlist[playerid] = nil
		self._citynum = self._citynum - 1
	end
end

function mapPlayerMgr:create_player(playerid)
	if self._playerlist[playerid] then
		gLog.w("mapPlayerMgr:create_player exist", playerid)
	else
		self._playerlist[playerid] = mapPlayerC.new(playerid)
		self:on_create_player()
	end
	return self._playerlist[playerid]
end

--发送给所有在地图且在线的玩家
function mapPlayerMgr:send_to_online(...)
	local group = {}
	for _, mapPlayer in pairs(self._playerlist) do
		if mapPlayer:is_online() then
			table.insert(group, mapPlayer:get_address())
		end
	end
	interaction.send_to_group(group, mapCenter.MAP_REMOTE, ...)
end

function mapPlayerMgr:on_create_player()
	local oldnum = self._citynum
	self._citynum = self._citynum + 1

	local cfg = get_static_config().worldmap_globals
	if oldnum < cfg.ServerNumlimit and self._citynum >= cfg.ServerNumlimit then
		local loginlist = config.get_login_list()
		for _,v in pairs(loginlist) do
			gLog.i("mapPlayerMgr:on_create_player update_city_full=", v.cluster_name, self._citynum)
			local address = clusterext.queryservice(v.cluster_name, "loginservice")
			clusterext.send(address, "lua", "update_city_full", config.get_server_id(), self:is_city_full())
		end
	end

	if not self._warning_count then
		self._warning_count = cfg.ServerNumWarning or 40000
	end
	if self._warning_count and oldnum < self._warning_count and self._citynum >= self._warning_count then
		require "httprequest".upload_logger(string.format("服务器人数报警 服务器id[%d] 人数[%d]", config.get_server_id(), self._citynum))
		self._warning_count = self._warning_count + 10000
	end
end

function mapPlayerMgr:is_city_full()
	local cfg = get_static_config().worldmap_globals
	return self._citynum >= cfg.ServerNumlimit
end

function mapPlayerMgr:get_city_num()
	return self._citynum
end

function mapPlayerMgr:get_attr(playerid, attr)
	if self._playerlist[playerid] then
		self._playerlist[playerid]:get_attr(attr)
	end
end

return mapPlayerMgr