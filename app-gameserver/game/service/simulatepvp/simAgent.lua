--[[
    模拟pvp客户端
]]
package.cpath =
        "skynet/luaclib/?.so;" ..
        "skynet/cservice/?.so;" ..
        "game/lib/lua-timer/?.so;" ..
        "game/lib/lua-lfs/?.so;" ..
        "game/lib/lua-bit32/?.so;" ..
        "game/lib/lua-enet/?.so;" ..
        "game/lib/lua-json/?.so;"

package.path =
        "./?.lua;" ..
        "skynet/lualib/?.lua;" ..
        "skynet/lualib/compat10/?.lua;" ..
        "game/lib/?.lua;" ..
        "game/lib/lua-timer/?.lua;" ..
        "game/lib/lua-json/?.lua;" ..
        "game/service/proto/?.lua;" ..
        "game/service/simulatepvp/?.lua;"

require "quickframework.init"
local simAgent = class("simAgent")

local host, port, uid, press = ...
host = tostring(host or "")
port = tonumber(port)
uid = tonumber(uid)
press = tonumber(press) or 0
assert(host and type(port) == "number" and uid, "usage: ./client.sh host port uid")

-- 构造
function simAgent:ctor()
    self.simGate = require("simGate").new()
    self.simGate:addEventListener(self.simGate.Gate_Success, handler(self, self.connectGateOk))
end

-- 连接网关成功
function simAgent:connectGateOk(event)
    print("simAgent:connectGateOk =", host, port, self.uid or uid, "index", self.simGate.index)
    self.simGate:handshake(self.uid or uid)
end

-- 启动客户端
if press >= 1 then -- 压测
    local clients = {}
    local socket = require("client.socket")
    local simGate = require("simGate")

    function simGate:onConnected()
        --print("simSocket:onConnected", self.name, self.host, self.port, self.fd, self.connected)
        self:dispatchEvent({name = simGate.Gate_Success})
        while(true) do
            local r = self:recv()
            if r then
                self:handleMsg(r)
            elseif self.connected then
                --print("f uid=", self.uid)
                coroutine.yield() -- socket.usleep(100)
            else
                print("simGate:onConnected break, sockect close!", self.name)
                break
            end
        end
        self:onFailure()
    end
    local f
    f = function(i)
        if i%100 == 0 then
            socket.usleep(100000) --1秒100人登录
        end
        local client = simAgent.new()
        simAgent.uid = (uid-1)*1000+i
        print("f begin uid=", simAgent.uid)
        client.simGate.i = i
        client.simGate:connectGate(host, port)
    end
    for i=1,press,1 do
        local co = coroutine.create(f)
        clients[i] = co
    end
    local ii = 0
    while(true) do
        while(true) do
            ii = ii + 1
            coroutine.resume(clients[ii], ii)
            if ii == press then
                ii = 0
                --print("f uid loop ii=", ii)
                break
            end
        end
        socket.usleep(100000) --0.01s
    end
else -- 非压测
    local client = simAgent.new()
    client.simGate:connectGate(host, port)
end



