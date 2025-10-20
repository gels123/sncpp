--[[
    缓存服务
--]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require "errDef"
local skynet = require("skynet")
local cluster = require("skynet.cluster")
local profile = require("skynet.profile")
local svrAddrMgr = require("svrAddrMgr")
local cacheCenter = require("cacheCenter"):shareInstance()

local kid = tonumber(...)
assert(kid)

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
        -- profile.start()

        --gLog.d("cacheCenter:dispatchCmd", session, source, cmd, ...)
        cacheCenter:dispatchCmd(session, source, cmd, ...)

        -- local time = profile.stop()
        -- if time > gOptTimeOut then
        --     gLog.w("cacheCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
        -- end
	end)
    -- 设置地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.cacheSvr, kid)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
    -- 通知启动服务，本服务已经初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.cacheSvr, kid), skynet.self())
end)
