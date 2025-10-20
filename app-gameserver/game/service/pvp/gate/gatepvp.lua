--[[
	pvp网关服务(使用可靠udp 或 tcp)
	Tips: 有些功能如聊天等, 可使用本微服务网关, 客户端tcp直连本服务, 也可不连由game服转发到chat服务。
]]
require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require "cluster"
require "errDef"
local skynet = require "skynet"
local netpack = require "skynet.netpack"
local profile = require "skynet.profile"
local rudpsvr = require("rudpsvr")
local gatepvpCenter = require("gatepvpCenter"):shareInstance()

local ti = {}
local kid, rudp = ...
kid, rudp = tonumber(kid), tonumber(rudp)
assert(kid > 0 and (rudp == 1 or rudp == nil))

-- 注册协议
skynet.register_protocol({
    name = "client",
    id = skynet.PTYPE_CLIENT, -- PTYPE_CLIENT = 3
})

-- 使用rudp
if rudp then
    local MSG = {
        [1] = assert(gatepvpCenter.open),
        [2] = assert(gatepvpCenter.close),
        [3] = assert(gatepvpCenter.dispatchMsg),
    }
    -- 注册协议
    skynet.register_protocol({
        name = "socket",
        id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET = 6
        unpack = rudpsvr.rudp_unpack,
        dispatch = function (_, _, t, ...)
            if t and MSG[t] then
                MSG[t](gatepvpCenter, ...)
            end
        end
    })

-- 使用tcp
else
    local MSG = {
        data = assert(gatepvpCenter.dispatchMsg),
        more = assert(gatepvpCenter.dispatchQueue),
        open = assert(gatepvpCenter.open),
        close = assert(gatepvpCenter.close),
        error = assert(gatepvpCenter.close),
    }
    -- 注册协议
    skynet.register_protocol({
        name = "socket",
        id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET = 6
        unpack = function (msg, sz)
            return netpack.filter(gatepvpCenter.queue, msg, sz)
        end,
        dispatch = function (session, source, q, t, ...)
            gatepvpCenter.queue = q
            if t and MSG[t] then
                MSG[t](gatepvpCenter, ...)
            end
        end
    })
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        profile.start()

        gatepvpCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 1 then
            gLog.w("gatepvpCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 注册 info 函数，便于 debug 指令 INFO 查询。
    skynet.info_func(function()
        gLog.i("info ti=", table2string(ti))
        return ti
    end)
    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid, rudp)
    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.gatepvpSvr, kid)
    -- 通知启动服务, 本服务已初始化完成
    require("serverStartLib"):finishInit(kid, svrAddrMgr.getSvrName(svrAddrMgr.gatepvpSvr, kid), skynet.self())
end)