--[[
	协议服务中心
]]
local skynet = require("skynet")
local lfs = require("lfs")
local sprotoloader = require("sprotoloader")
local sprotoparser = require("sprotoparser")
local serviceCenterBase = require("serviceCenterBase")
local protoCenter = class("protoCenter", serviceCenterBase)

-- 构造
function protoCenter:ctor()
	protoCenter.super.ctor(self)
end

-- 初始化
function protoCenter:init()
	gLog.i("==protoCenter:init begin==")

	-- 更新共享协议(使用sproto)
	self:updateSproto()

	-- 更新共享协议(使用protobuf)
	-- self:updateProtobuf()

    gLog.i("==protoCenter:init end==")
end

-- 更新共享协议(sproto)
function protoCenter:updateSproto()
	gLog.i("==protoCenter:updateSproto begin==")
	local curdir = lfs.currentdir()

	-- c2s客户端到服务端的协议
	local c2sFiles = {"types.sproto",}
	for fileName in lfs.dir(curdir.."/game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.c2s.sproto$") then
			table.insert(c2sFiles, fileName)
		end
	end
	local c2sSproto = ""
	for _,fileName in pairs(c2sFiles) do
		c2sSproto = c2sSproto.."\n"..io.readfile(curdir.."/game/service/proto/sproto/"..fileName)
	end
	--gLog.d("protoCenter:updateSproto c2sSproto=", c2sSproto)
	local c2sPb = assert(sprotoparser.parse(c2sSproto))
	sprotoloader.save(c2sPb, 1)

	-- 服务端到客户端的协议
	local s2cFiles = {"types.sproto",}
	for fileName in lfs.dir(curdir.."/game/service/proto/sproto/") do
		if string.find(fileName, "[%w_]+.s2c.sproto$") then
			table.insert(s2cFiles, fileName)
		end
	end
	local s2cSproto = ""
	for _,fileName in pairs(s2cFiles) do
		s2cSproto = s2cSproto.."\n"..io.readfile(curdir.."/game/service/proto/sproto/"..fileName)
	end
	--gLog.d("protoCenter:updateSproto s2cSproto=", s2cSproto)
	local s2cPb = assert(sprotoparser.parse(s2cSproto))
	sprotoloader.save(s2cPb, 2)

	gLog.i("==protoCenter:updateSproto end==")
end

-- 更新共享协议(protobuf)
function protoCenter:updateProtobuf()
	gLog.i("==protoCenter:updateProtobuf begin==")
	local curdir = lfs.currentdir()
	local pb = require('pb')
	local pc = require('protoc').new()
	pc:addpath(curdir.."/game/service/proto/protobuf/")

	local file = io.open(curdir.."/game/service/proto/protobuf/lordinfo.proto", "r")
	assert(pc:load(file:read("*a")))
	local file = io.open(curdir.."/game/service/proto/protobuf/login.proto", "r")
	assert(pc:load(file:read("*a")))
 
	 ---@type ClientLoading_Response_101
	 local sendMsg = {
	 	uid = 1201,
	 	lordData = {
	 		uid = 1201,
	 		nickName = "test1201",
	 		level = 2,
	 	}
	}
	local serDATA = pb.encode("login.LoginInitData", sendMsg)
	 
	local result = {}
	result = pb.decode("login.LoginInitData", serDATA)
	gLog.dump(result, "updateProtobuf result=", 10)


	gLog.i("==protoCenter:updateSproto end==")
end

-- 测试sproto
function protoCenter:testSproto()
	local name = "cs_test_say"
	local data = {
		uid = 1201,
		text = "hello",
	}
	local encodeStr = require("protoLib"):c2sEncode(name, data, 1) -- 客户端请求加码
	gLog.i("protoCenter:updateSproto test1 encodeStr=", encodeStr)
	local type1, name1, data1, response1 = require("protoLib"):c2sDecode(encodeStr) -- 客户端请求解码
	gLog.dump(type1, "protoCenter:updateSproto test1 type1=", 10)
	gLog.dump(name1, "protoCenter:updateSproto test1 name1=", 10)
	gLog.dump(data1, "protoCenter:updateSproto test1 data1=", 10)
	gLog.dump(response1, "protoCenter:updateSproto test1 response1=", 10)
	if response1 then
		return response1({result = "0", newtext = "good"})
	end

	local name = "sc_test_notify"
	local data = {
		uid = 1201,
		str = "nihao",
	}
	local encodeStr = require("protoLib"):s2cEncode(name, data, 1) -- 服务端请求加码
	gLog.i("protoCenter:updateSproto test2 encodeStr=", encodeStr)
	local type1, name1, data1, response1 = require("protoLib"):s2cDecode(encodeStr) -- 服务端请求解码
	gLog.dump(type1, "protoCenter:updateSproto test1 type2=", 10)
	gLog.dump(name1, "protoCenter:updateSproto test1 name2=", 10)
	gLog.dump(data1, "protoCenter:updateSproto test1 data2=", 10)
	gLog.dump(response1, "protoCenter:updateSproto test2 response1=", 10)
end

return protoCenter
