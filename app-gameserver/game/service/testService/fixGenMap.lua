local skynet = require ("skynet")
local profile = require "profile"
require "quickframework.init"
require "configInclude"
include "constDefInit"
require "svrFunc"
require "sharedataLib"
local playerDataLib = include("playerDataLib")

xpcall(function()
gLog.i("=====fixGenMap begin")
	
	
	--生成文件
    local fileName = require("lfs").currentdir() .. "/testmap1.lua"
    local file = io.open(fileName, "w")
    gLog.d("fixGenMap file=", fileName, file)
    io.output(file)

    -- io.write("local map = \n\"")
   	local line = ""
    for i = 1, 1200, 1 do
    	line = string.format("%s%s", line, 0)
    end
    for i = 1, 1200, 1 do
      io.write(string.format("%s\n", line))
    end
    -- io.write("\"\nreturn map")
    io.close(file)


    local file = io.open(fileName, "r")
	io.input(file)
	print(io.read("*a"))




gLog.i("=====fixGenMap end")
end,svrFunc.exception)

