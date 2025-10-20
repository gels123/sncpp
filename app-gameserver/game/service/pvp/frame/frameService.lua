--[[
    帧同步服务
]]
require "quickframework.init"
require "svrFunc"
require "errDef"
require "configInclude"
require "sharedataLib"
require "cluster"
require "pvpDef"
local skynet = require "skynet"
local svrAddrMgr = require "svrAddrMgr"
local frameCenter = require("frameCenter"):shareInstance()

local kid, idx, rudp = ...
kid, idx, rudp = tonumber(kid), tonumber(idx), tonumber(rudp)
assert(kid and idx and (rudp == 1 or rudp == nil))

-- 注册客户端协议
skynet.register_protocol({
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = skynet.unpack,
    dispatch = function(_, _, fd, msg, sz)
        --gLog.d("frameService dispatch=", _, _, fd, msg, sz)
        if fd and msg then
            frameCenter:dispatchMsg(fd, msg, sz)
        end
    end,
})

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        --gLog.d("frameCenter cmd enter => ", session, source, cmd, ...)
        frameCenter:dispatchCmd(session, source, cmd, ...)
    end)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, idx, rudp)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.frameSvr, kid, idx)
    -- 通知启动服务, 本服务已初始化完成
     require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.frameSvr, kid, idx), skynet.self())
end)
