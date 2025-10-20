-------fixgate.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()	
gLog.i("=====fixgate begin")
print("=====fixgate begin")


	local gateCenter = require("gateCenter"):shareInstance()

	-- -- local address = svrAddrMgr.getSvr(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
	-- -- skynet.call(address, "lua", "login", 1201, 1, false, secret, version, plateform, model, addr)

	-- -- gLog.dump(gateCenter, "==gateCenter==", 10)

	-- local ok, err = pcall(function ()
	-- 	error("2343434")
	-- end)
	-- print("==s=dfasdfa===", ok, err)
	-- gateCenter:__gc()
	gateCenter:kill()

	
gLog.i("=====fixgate end")
print("=====fixgate end")
end,svrFunc.exception)