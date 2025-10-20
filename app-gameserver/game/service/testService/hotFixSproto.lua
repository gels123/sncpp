--[[
	hotFixSproto.lua 
	用法:
	log fixServiceByLogService protoService game/service/testService/hotFixSproto.lua
]]
local skynet = require ("skynet")
local cluster = require ("cluster")
local sprotoloader = require("sprotoloader")

xpcall(function()	
gLog.i("=====hotFixSproto begin")
print("=====hotFixSproto begin")
	
	-- 方式1
	local protoCenter = include("protoCenter"):shareInstance()
	local protoTest2 = require "protoTest2"
	protoCenter:updateSproto(protoTest2)

	-- 方式2
	-- local sprotoparser = require "sprotoparser"
	-- local proto = {}

	-- proto.c2s = sprotoparser.parse([[
	-- .package {
	--     type 0 : integer
	--     session 1 : integer
	-- }

	-- handshake 1 {
	--     response {
	--         msg 0 : string
	--     }
	-- }

	-- say 2 {
	--     request {
	--         name 0 : string
	--         msg 1 : string
	--         num 2 : integer
	--         num22 3 : integer
	--     }
	-- }

	-- quit 3 {}

	-- ]])

	-- proto.s2c = sprotoparser.parse([[
	-- .package {
	--     type 0 : integer
	--     session 1 : integer
	-- }

	-- heartbeat 1 {}
	-- ]])

	-- sprotoloader.save(proto.c2s, 1) --客户端到服务端的协议
	-- sprotoloader.save(proto.s2c, 2) --服务端到客户端的协议


gLog.i("=====hotFixSproto end")
print("=====hotFixSproto end")
end,svrFunc.exception)