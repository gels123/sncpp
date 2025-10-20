-------fixSproto.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()	
gLog.i("=====fixSproto begin")
print("=====fixSproto begin")

	local name = "say"
	local data = {
		name = "soul", 
		msg = "hello world",
		num = 111,
		num22 = 222,
	}
	local protoLib = require ("protoLib")
	local encodeStr = protoLib:c2sEncode(name, data, 1)
	gLog.i("=========sdfs=df===encodeStr=", encodeStr)

	-- local a,b,c,d = protoLib:c2sDecode(encodeStr)
	-- gLog.dump(a, "=========sdfs=df===a=", 9)
	-- gLog.dump(b, "=========sdfs=df===b=", 9)
	-- gLog.dump(c, "=========sdfs=df===c=", 9)
	-- gLog.dump(d, "=========sdfs=df===d=", 9)

	skynet.call(svrAddrMgr.getSvr(svrAddrMgr.startSvr, 1), skynet.PTYPE_CLIENT, name, encodeStr)


gLog.i("=====fixSproto end")
print("=====fixSproto end")
end,svrFunc.exception)