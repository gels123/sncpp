--[[
	热更修复样例: 分析日志文件, 得到数据源
    log fixServiceByLogService powerKidActivityService game/service/testService/fixFromLogFile.lua
]]
local skynet = require ("skynet")
local profile = require "profile"
require "quickframework.init"
require "configInclude"
include "constDefInit"
require "svrFunc"
local json = require("json")
local sharedata = require ("sharedataLib")
local playerDataLib = include("playerDataLib")
local nodeAPI = include("nodeAPI")

xpcall(function ( ... )
gLog.i("=====fixFromLogFile begin")
print("=====fixFromLogFile begin")
	
	local powerKidActivityCenter = include("powerKidActivityCenter"):shareInstance()
	local kid = powerKidActivityCenter.kid

	local shell = string.format('grep "powerKidActivityPlayer:checkData" /data/roklog/game_release_%s.21-7-*.*', kid)
	if kid > 10000 then
		shell = string.format('grep "powerKidActivityPlayer:checkData" /data/roklog/game_release_%s.21-7-*.*', kid-1)
	end
	local t = io.popen(shell)
	local a = t:read("*all")
	print("==shell=", shell)
	print("==shell a=", a)
	local arr = svrFunc.split(a, "\n")
	if arr and next(arr) then
		local tmpList = {}
		for _,str in pairs(arr) do
			if string.len(str) > 0 then
				local posidx = string.find(str, "reset")
				if posidx then
					str = string.sub(str, posidx+7, -1)
					print("=fixFromLogFile fix do1=", str)
					gLog.i("=fixFromLogFile fix do1=", str)
					if str then
						local arrstr = svrFunc.split(str, " ")
						if arrstr then
							local uid, num = tonumber(arrstr[1]), tonumber(arrstr[2])
							print("=fixFromLogFile fix do2=", uid, num)
							gLog.i("=fixFromLogFile fix do2=", uid, num)
							if uid and uid > 0 and num and num > 0 then
								if num > (tmpList[uid] or 0) then
									tmpList[uid] = num
								end
							end
						end
					end
				end
			end
		end
		for uid, num in pairs(tmpList) do 
			print("=fixFromLogFile fix do4=", uid, num)
			gLog.i("=fixFromLogFile fix do4=", uid, num)
			local powerKidActivityPlayer = powerKidActivityCenter.powerKidActivityPlayerMgr:getMember(uid)
			if powerKidActivityPlayer.data.accuScore ~= num then
				powerKidActivityPlayer.data.accuScore = num
			end
			powerKidActivityPlayer:saveDB()
		end
	end
	

gLog.i("=====fixFromLogFile end")
print("=====fixFromLogFile end")
end, svrFunc.exception)


