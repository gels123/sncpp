--[[
    服务端代理（已废弃）
]]
local simProxy = class("simProxy")

-- 定义事件 下边的四个事件是 simProxy 向外部报告的事件
-- 只游戏登录，或者网关握手的时候出错
simProxy.EVENT_GAME_REJECTED = "SERVERPROXY_GAME_REJECTED_EVENT"

-- 成功进入游戏，可以开始游戏初始化
simProxy.EVENT_GAME_ENTERED = "SERVERPROXY_GAME_ENTERED_EVENT"

-- 网络掉线
simProxy.EVENT_SERVER_DISCONNECTED = "SERVERPROXY_SERVER_DISCONNECTED_EVENT"

-- 构造
function simProxy:ctor()
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- 请求session, 可复用
    self.session = 0

    -- 
    self.simLogin = require("simLogin").new()
    self.simLogin:addEventListener(self.simLogin.LOGIN_SUCCESS, handler(self, self.onLoginSuccess))
    self.simGate = require("simGate").new()
    self.simGate:addEventListener(self.simGate.GATE_CONNECT_SUCCESS, handler(self, self.onGateConnectSuccess))
    self.simGate:addEventListener(self.simGate.GATE_HANDSHAKE_SUCCESS, handler(self, self.onGateHandshakeSuccess))

    -- 是否停止
    self.isStoped = false
end

-- 连接登录服
function simProxy:connectLogin(user)
    gLog.i("simProxy:connectLogin user=", user)
    local host = "127.0.0.1"
    local port = 26000
    local token = {
        user = user or "test1201",
        pass = "password",
        subtoken = "testsubtoken",
    }
    self.simLogin:connectLogin(host, port, token)
end

-- 连接登录服成功
function simProxy:onLoginSuccess(event)
    gLog.i("simProxy:onLoginSuccess", self.simLogin.gateip, self.simLogin.gateport)
    assert(self.simLogin.gateip and self.simLogin.gateport)
    self.simGate:connectGate(self.simLogin.gateip, self.simLogin.gateport)
end

-- 连接网关成功
function simProxy:onGateConnectSuccess(event)
    gLog.i("simProxy:onGateConnectSuccess gatenodeid=", self.simLogin.gatenodeid, "uid=", self.simLogin.uid, "subid=", self.simLogin.subid, "secret=", self.simLogin.secret, "index=", self.simGate.index)
    assert(self.simLogin.gatenodeid and self.simLogin.uid and self.simLogin.subid and self.simLogin.secret)
    self.simGate:handshake(self.simLogin.uid, self.simLogin.gatenodeid, self.simLogin.subid, self.simLogin.secret)
end

-- 网关握手成功
function simProxy:onGateHandshakeSuccess(event)
    gLog.i("simProxy:onGateHandshakeSuccess")
    --请求登陆初始化数据
    self:reqLoginInitData()
end

--请求登陆初始化数据
function simProxy:reqLoginInitData()
    self:sendRequest(gCmd.CMD_LOGIN, gCmd.REQ_LOGIN_INIT_DATA, {})
end

-- 发起请求
function simProxy:sendRequest(cmd, subcmd, data)
    if self.isStoped then
        return
    end
    local msg = {
        cmd = cmd,
        subcmd = subcmd,
        data = data
    }
    local session = (self.session or 0)
    self.session = session + 1
    self.simGate:sendMsg(session, msg)
end


--注销操作
function simProxy:Logout()
    self.loginCtrl_:Logout()
end

--被踢停止工作
function simProxy:Stop()
    self.isStoped = true
end

----------------------loginCtrl回调函数----------------
function simProxy:gameEnter()
    local uid = self.loginCtrl_.login_.uid
    local kid = self.loginCtrl_.login_.kingdomId
	self:dispatchEvent({name = simProxy.EVENT_GAME_ENTERED,uid = uid,kid = kid})
end

function simProxy:gameRejected()
end

--服务器维护
function simProxy:serverMaintaince()
end

--封号
function simProxy:beSealed()

end

--网关断开
function simProxy:gameDisconnected()
    self:dispatchEvent({name = simProxy.EVENT_SERVER_DISCONNECTED})
end

return simProxy




