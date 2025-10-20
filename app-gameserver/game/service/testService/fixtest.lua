-------fixtest.lua
-------
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")

xpcall(function()
	--gLog.i("=====fixtest begin")
	print("=====fixtest begin")

	--local publicRedisLib = require("publicRedisLib")
	--publicRedisLib:subscribe(dbconf.publicRedis, "gels", function(data, channel)
	--	gLog.d("playerDataCenter:subscribe receive", channel, data, table2string(json.decode(data)))
	--end)

	--local f = function()
	--	local ok, data = xpcall(function()
	--		return redisLib:message("channel1")
	--	end, svrFunc.exception)
	--	gLog.d("playerDataCenter:subscribe receive", ok, data)
	--end
	--local ok = redisLib:subscribe(dbconf.publicRedis, "channel1")
	--if ok then
	--	skynet.fork(function(f)
	--		while true do
	--			f()
	--		end
	--	end, f)
	--end


	-- local data = {
	-- 	v = 1,
	-- 	num = 100,
	-- 	son1 = {
	-- 		age = 4,
	-- 	}
	-- }
	-- local decode
	--decode = function(_t)
	--	if type(_t) == "table" then
	--		local _meta = getmetatable(_t)
	--		if type(_meta) == "table" and type(_meta.__index) == "table" then
	--			_t = _meta.__index
	--		end
	--		for k,v in pairs(_t) do
	--			_t[k] = decode(v)
	--		end
	--		return _t
	--	else
	--		return _t
	--	end
	--end
	-- local encode
	--encode = function(_t)
	--	if type(_t) == "table" then
	--		for k,v in pairs(_t) do
	--			_t[k] = encode(v)
	--		end
	--		local _newt = setmetatable({}, {
	--			__newindex = function(t, k, v)
	--				if type(v) == "table" then
	--					local _v = rawget(_t, k)
	--					if type(_v) == "table" then
	--						local _vmeta = getmetatable(_v)
	--						if not (type(_vmeta) == "table" and _vmeta.__index == v) then
	--							gLog.info("__newindex set k=%s v=%s", k, v)
	--							rawset(_t, k, encode(v))
	--						end
	--					else
	--						gLog.info("__newindex set k=%s v=%s", k, v)
	--						rawset(_t, k, encode(v))
	--					end
	--				else
	--					if rawget(_t, k) ~= v then
	--						gLog.info("__newindex set k=%s v=%s", k, v)
	--						rawset(_t, k, v)
	--					end
	--				end
	--			end,
	--			__index = _t,
	--			__len = function(t)
	--				return #_t
	--			end,
	--			__pairs = function(t)
	--				return next, _t, nil
	--			end
	--		})
	--		return _newt
	--	end
	--	return _t
	--end

	-- local tab  = encode(data)
	-- tab.num = 200
	-- tab.newnum = 300
	-- tab.newnum = 400
	-- local tmp = {age = 5}
	-- tab.son1 = tmp
	-- tab.son1 = tmp
	-- tmp.age = 40
	-- tab.son1.age = 50
	-- tab.son1.age = 60
	-- tab.son1.age = 60

	-- gLog.info("num=%s newnum=%s json=%s %s", tab.num, tab.newnum, require("json").encode(tab), require("json").encode(decode(tab)))
	-- gLog.dump(tab, "tab=====")
	-- gLog.dump(decode(tab), "tab=====")

	-- local eventLib = require("eventLib")
	-- eventLib:dispatchEvent(200001, 0, {aName = "xxx"})

	-- mongodbsvr = skynet.newservice("mongodbService", "master", dbconf.mongodb_gamedb.instance)
	-- svrAddrMgr.setSvr(mongodbsvr, ".mongodb")
	-- skynet.call(mongodbsvr, "lua", "connect", dbconf.mongodb_gamedb)

	-- mongodbsvr = svrAddrMgr.getSvr(".mongodb")
	-- -- skynet.call(mongodbsvr, "lua", "safe_insert", 1001, "lord", {name = "lll23"})
	-- -- skynet.call(mongodbsvr, "lua", "safe_update", 1001, "lord", {name = "66777"})
	-- -- skynet.call(mongodbsvr, "lua", "safe_update", 1002, "lord", {name = "c9999"})
	-- local ret = skynet.call(mongodbsvr, "lua", "execute", "findOne", 1001, "lord")
	-- gLog.dump(ret, "xx11111")


	local playerDataLib = require("playerDataLib")
	-- local fakeTime = require("playerDataLib"):query(1, 1, "faketime") or {}
	-- fakeTime.sec = (fakeTime.sec or 0) + 1
	-- playerDataLib:update(1, 1, "faketime", fakeTime)

	-- local lordinfo = require("playerDataLib"):query(1, 1001, "lordinfo") or {}
	-- lordinfo.aa = lordinfo.aa + 1
	-- playerDataLib:update(1, 1001, "lordinfo", {aa=10000})
	-- playerDataLib:sendUpdate(1, 1001, "lordinfo", {aa=10002})

	-- local gameDBSvr = svrAddrMgr.getSvr(svrAddrMgr.gameDBSvr)
	-- skynet.call(gameDBSvr, "lua", "disconnect", dbconf.mysql_gamedb)

	-- local lordinfo = {}
	-- lordinfo.aa = 1005
	-- playerDataLib:sendUpdate(1, 1001, "lordinfo", lordinfo)
	-- lordinfo.aa = 2005
	-- playerDataLib:sendUpdate(1, 1001, "lordinfo", lordinfo)
	-- playerDataLib:sendDelete(1, 1001, "lordinfo")
	-- lordinfo.aa = 3005
	-- playerDataLib:sendUpdate(1, 1001, "lordinfo", lordinfo)
	-- local ret = playerDataLib:query(1, 1001, "lordinfo")
	-- gLog.dump(ret, "xx11111")

	-- skynet.sleep(6000)
	-- local gameDBSvr = svrAddrMgr.getSvr(svrAddrMgr.gameDBSvr)
	-- skynet.call(gameDBSvr, "lua", "reconnect", dbconf.mysql_gamedb)

	-- playerDataLib:getKidOfUid(1, 1000)


	-- local redisLock = require("redisLock")
	-- redisLock.trylock("gelslock", 10)
	-- redisLock.trylock("gelslock", 10)
	-- redisLock.unlock("gelslock")


	-- local chash = require ("chash")
	-- local hash = chash.fnv_hash("lord"..1006)
	-- gLog.i("=====hash=", hash)


	local fullyWeak = setmetatable({}, {__mode = "kv"})
	fullyWeak[1006] = require("skynet.queue")()
	gLog.i("fullyWeak1===", table.nums(fullyWeak), fullyWeak[1006])
	for k,v in pairs(fullyWeak) do
		gLog.i("=====fullyWeak1 k=", k, " ", v)
	end
	skynet.fork(function()
		fullyWeak[1006](function()
			gLog.i("step11111111111 begin")
			skynet.sleep(1000)
			gLog.i("step11111111111 end")
		end)
	end)

	skynet.fork(function()
		-- collectgarbage("collect") 
		fullyWeak[1006](function()
			gLog.i("step2222222222 begin")
			skynet.sleep(500)
			gLog.i("step22222222222 end")
		end)
	end)
	
	

	-- gLog.i("fullyWeak2===", table.nums(fullyWeak))
	-- for k,v in pairs(fullyWeak) do
	-- 	gLog.i("=====fullyWeak2 k=", k, " ", v)
	-- end
	
	gLog.i("=====fixtest end", fullyWeak[1006])
	print("=====fixtest end")
end,svrFunc.exception)