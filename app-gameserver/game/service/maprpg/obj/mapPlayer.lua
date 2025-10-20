--[[
	玩家数据缓存
		字段见 mapConf.player_field 定义
--]]
local skynet = require "skynet"
local mapPlayer = class("mapPlayer")

function mapPlayer:ctor(playerid)
	self.playerid = playerid

	self._playercache = nil 	--玩家缓存数据
	self._online = nil 			--是否在线
end

function mapPlayer:get_playerid()
	return self.playerid
end

function mapPlayer:get_address()
	return self._address
end

function mapPlayer:is_online()
	return self._online
end

function mapPlayer:set_online(flag)
	self._online = flag
end

function mapPlayer:set_player_cache(info)
	self._playercache = info
end

function mapPlayer:update_player_cache(field, value)
	local oldValue = self._playercache[field]
	if oldValue ~= value then
		self._playercache[field] = value
		if mapConf.notify_player_field[field] then
			return true, oldValue
		end
	end
end

function mapPlayer:get_attr(attr)
	return self._playercache and self._playercache[attr] or nil
end

--玩家头像
function mapPlayer:get_head()
	return (self._playercache.head or 0) > 0 and self._playercache.head or 1
end

function mapPlayer:get_name()
	return self._playercache.name or ""
end

--玩家头像框
function mapPlayer:get_border()
	return self._playercache.border or 0
end

function mapPlayer:get_skin()
	return self._playercache.skin or 0
end

function mapPlayer:get_skintime()
	return self._playercache.skintime or 0
end

function mapPlayer:get_castle_level()
	return self._playercache.castlelv or 0
end

function mapPlayer:get_level()
	return self._playercache.level
end

function mapPlayer:get_language()
	return self._playercache.language
end

function mapPlayer:get_guild_id()
	return self._playercache.guildid or 0
end

function mapPlayer:get_guild_short()
	return self._playercache.guildshort
end

function mapPlayer:get_guild_name()
	return self._playercache.guildname
end

function mapPlayer:get_guild_banner()
	return (self._playercache.guildbanner or 0) > 0 and self._playercache.guildbanner or 1
end

function mapPlayer:get_server_id()
	return self._playercache.kid
end

function mapPlayer:get_shieldover()
	return self._playercache.shieldover or 0
end

function mapPlayer:get_walllv()
	return self._playercache.walllv and self._playercache.walllv > 0 and self._playercache.walllv or 1
end

function mapPlayer:get_score()
	return self._playercache.score or 0
end

function mapPlayer:get_build()
	return self._playercache.build or 0
end

return mapPlayer