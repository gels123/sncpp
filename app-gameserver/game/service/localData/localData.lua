--[[
    本地静态配置数据加载服务
--]]
require "quickframework.init"
require "svrFunc"
require "sharedataLib"
local skynet = require("skynet")
local cluster = require("skynet.cluster")
local profile = require("skynet.profile")
local svrAddrMgr = require("svrAddrMgr")
local localDataLogic = require("localDataLogic")

local CMD = {}

-- 热更
function CMD.hotfix()
	local ok = pcall(function()
		localDataLogic:init(true)
	end)
	if ok then
		gLog.i("localData.hotfix reload configs success")
	else
		gLog.i("localData.hotfix reload configs fail")
	end
	skynet.retpack(ok)
end

skynet.start(function()
	-- 设置本地静态配置数据(local data) 到 sharedata 中
	localDataLogic:init()

	skynet.dispatch("lua", function(session, source, cmd, ...)
		profile.start()

		local f = assert(CMD[cmd], "localData unknown cmd " .. cmd)
		f(...)

		local time = profile.stop()
		if time > 1 then
			gLog.w("localData:dispatchCmd timeout time=", time, "cmd=", cmd, ...)
		end
	end)
	-- 设置地址
	svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.localData)
end)
