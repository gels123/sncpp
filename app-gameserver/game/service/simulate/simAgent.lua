--[[
    模拟客户端
]]
package.cpath =
        "skynet/luaclib/?.so;" ..
        "skynet/cservice/?.so;" ..
        "game/lib/lua-timer/?.so;" ..
        "game/lib/lua-socket/src/?.so;" ..
        "game/lib/lua-lfs/?.so;" ..
        "game/lib/lua-bit32/?.so;" ..
        "game/lib/lua-json/?.so;"

package.path =
        "?.lua;" ..
        "skynet/lualib/?.lua;" ..
        "skynet/lualib/compat10/?.lua;" ..
        "game/lib/?.lua;" ..
        "game/lib/lua-timer/?.lua;" ..
        "game/lib/lua-socket/?.lua;" ..
        "game/lib/lua-json/?.lua;" ..
        "game/service/proto/?.lua;" ..
        "game/service/simulate/?.lua;"

require "quickframework.init"
local socket = require "client.socket"
local crypt = require "client.crypt"
local lfs = require("lfs")
local socket = require "src.socket"
local clientsocket = require "client.socket"
local sproto = require "sproto"
local sprotoparser = require "sprotoparser"
local simAgent = class("simAgent")


local host, port, user = ...
host = tostring(host)
port = tonumber(port)
user = tostring(user)
assert(host and type(port) == "number" and user, "usage: ./client.sh host port user (eg: ./client.sh 127.0.0.1 6001 1000)")


-- 构造
function simAgent:ctor()
    --
    self.simLogin = require("simLogin").new()
    self.simLogin:addEventListener(self.simLogin.Login_Success, handler(self, self.connectLoginOk))
    self.simGate = require("simGate").new()
    self.simGate:addEventListener(self.simGate.Gate_Success, handler(self, self.connectGateOk))
end

-- 连接登录服
function simAgent:connectLogin(host, port, user)
    --print("simAgent:connectLogin host=", host, "port=", port, "user=", user)
    local token = {
        user = user or "test1201",
        pass = "pwd",
        subtoken = "subtoken",
    }
    host = socket.dns.toip(host) or host or "127.0.0.1"
    self.simLogin:connectLogin(host, port or 26000, token)
end

-- 连接登录服成功
function simAgent:connectLoginOk(event)
    print("simAgent:connectLoginOk", self.simLogin.ip, self.simLogin.port)
    assert(self.simLogin.ip and self.simLogin.port)
    self.simGate:connectGate(self.simLogin.ip, self.simLogin.port)
end

-- 连接网关成功
function simAgent:connectGateOk(event)
    print("simAgent:connectGateOk nodeid=", self.simLogin.nodeid, "uid=", self.simLogin.uid, "subid=", self.simLogin.subid, "secret=", self.simLogin.secret, "index=", self.simGate.index)
    assert(self.simLogin.nodeid and self.simLogin.uid and self.simLogin.subid and self.simLogin.secret)
    self.simLogin.ip = socket.dns.toip(self.simLogin.ip) or self.simLogin.ip
    self.simGate:handshake(self.simLogin.uid, self.simLogin.nodeid, self.simLogin.subid, self.simLogin.secret)
    -- 删除simLogin
    self.simLogin:removeEventListenersByEvent(self.simLogin.Login_Success)
    self.simLogin = nil
end

-- 启动客户端
--print("simClient login host=", host, "port=", port, "user=", user)
client = simAgent.new()
client:connectLogin(host, port, user)



