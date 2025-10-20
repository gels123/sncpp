-------fixrudp.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")
local socket2 = require "client.socket"

xpcall(function()	
gLog.i("=====fixrudp begin")
print("=====fixrudp begin")

	local function send_package(fd, pack)
		local package = string.pack(">s2", pack)
		socket2.send(fd, package)
	end

	
	-- local socket = require "skynet.socket"
	-- local c = socket.udp(function(str, from)
	-- 	print("client recv=", str, socket.udp_address(from))
	-- end)
	-- socket.udp_connect(c, "127.0.0.1", 24101)
	-- socket.write(c, "hello " .. 100)	-- write to the address by udp_connect binding


	-- local socket = require "client.socket"
	-- local fd = assert(socket.connect("127.0.0.1", 24101))
 --    socket.send(fd, "hello 100")

 	-- tcp
 	
 	local fd = assert(socket2.connect("127.0.0.1", 24101))
 	send_package(fd, "aabbcc123")

gLog.i("=====fixrudp end")
print("=====fixrudp end")
end,svrFunc.exception)