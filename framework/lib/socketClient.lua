--[[
	客户端TCP套接字封装
	Created by Gels on 2021/8/19.
]]
local skynet = require("skynet")
local skynettimer = require("skynettimer")
local socket = require("client.socket")
local socketClient = class("socketClient")

local SOCKET_TICK_TIME = 10 			-- check socket data interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 300	-- socket failure timeout

-- 定义事件
socketClient.EVENT_DATA = "SOCKET_DATA" -- 接收到数据事件
socketClient.EVENT_CLOSED = "SOCKET_CLOSED" -- 连接关闭事件
socketClient.EVENT_CONNECTED = "SOCKET_CONNECTED" -- 连接成功事件
socketClient.EVENT_CONNECT_FAILURE = "SOCKET_CONNECT_FAILURE" -- 连接失败事件

-- 构造
function socketClient:ctor(host, port, name)
	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    self.host = host -- ip
    self.port = port -- 端口
    self.name = name or "socketClient" -- 名字

    self.fd = nil
    self.isConnected = false

    self.timer = skynettimer.new()
    self.timer:start()

    self.waitConnect = nil -- 连接耗时
	self.tickTimerID = nil -- timer for data
	self.connectTimerID = nil -- timer for connect timeout
end

-- 设置名字
function socketClient:setName(name)
	self.name = name
end

function socketClient:setTickTime(time)
	SOCKET_TICK_TIME = time
end

function socketClient:setConnFailTime(time)
	SOCKET_CONNECT_FAIL_TIMEOUT = time
end

-- 连接服务器
function socketClient:connect(host, port)
	if host then
		self.host = host 
	end
    if port then
    	self.port = port 
    end
    assert(self.host or self.port, "socketClient:connect error: host and port are necessary!")
    gLog.i("socketClient:connect host=", self.name, self.host, "port=", self.por)
    -- 连接服务器
    self:_connect()
end

-- 发送数据
function socketClient:send(package)
	gLog.i("socketClient:send", self.name, self.fd, package)
	assert(self.isConnected, self.name .. " is not connected.")
	socket.send(self.fd, package)
end

-- 关闭连接
function socketClient:close()
	gLog.i("socketClient:close", self.name)
	if self.fd then
		socket.close(self.fd)
		self.fd = nil
		self.isConnected = false
	end
	if self.tickTimerID then
		self.timer:delete(self.tickTimerID)
		self.tickTimerID = nil
	end
	if self.connectTimerID then
		self.timer:delete(self.connectTimerID)
		self.connectTimerID = nil
	end
end

-- 关闭连接并通知事件
function socketClient:disconnect()
	self:close()
	self:_onDisconnect()
end

--------------------
-- private
--------------------

-- 连接服务器
function socketClient:_connect()
	if self.fd then
		gLog.i("socketClient:_connect close", self.fd)
		socket.close(self.fd)
		self.fd = nil
		self.isConnected = false
	end
	local fd = socket.connect(self.host, self.port)
	if fd then
		-- 连接成功
		gLog.i("socketClient:_connect success", self.host, self.port)
		self.fd = fd
		self.isConnected = true
		self:_onConnected()
	else
	    -- check whether connection is success
		-- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
		local __connectTimeTick = function ()
			if self.connectTimerID then
				self.timer:delete(self.connectTimerID)
				self.connectTimerID = nil
			end
			if self.isConnected then
				return
			end
			self.waitConnect = (self.waitConnect or 0) + SOCKET_TICK_TIME
			if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
				gLog.i("socketClient:_connect failed", self.host, self.port)
				self.waitConnect = nil
				self:close()
				self:_onConnectFailure()
				return
			end
			self:_connect()
		end
		self.connectTimerID = self.timer:add(SOCKET_TICK_TIME, __connectTimeTick)
	end
end

-- 连接成功
function socketClient:_onConnected()
	self:dispatchEvent({name = socketClient.EVENT_CONNECTED})

	if self.connectTimerID then
		self.timer:delete(self.connectTimerID)
		self.connectTimerID = nil
	end

	local __tick = nil
	__tick = function()
		-- gLog.d("socketClient:_onConnected __tick")
		while true do
			if not self.isConnected then
				break
			end
			local r = socket.recv(self.fd)
			-- gLog.d("socketClient:_onConnected __tick socket.recv=", r)
			if r == "" then -- Server closed
		    	self:close()
		    	self:_onDisconnect()
		    	break
	    	end
	    	if r == nil then
	    		break
	    	end
			self:dispatchEvent({name = socketClient.EVENT_DATA, data = r})
		end
		if self.tickTimerID then
			self.timer:delete(self.tickTimerID)
			self.tickTimerID = nil
		end
		if self.isConnected then
			self.tickTimerID = self.timer:add(SOCKET_TICK_TIME, __tick)
		end
	end
	-- start to read TCP data
	self.tickTimerID = self.timer:add(SOCKET_TICK_TIME, __tick)
end

function socketClient:_onDisconnect()
	gLog.i("socketClient:_onDisconnect", self.name)
	self:dispatchEvent({name = socketClient.EVENT_CLOSED})
end

function socketClient:_onConnectFailure()
	gLog.i("socketClient:_onConnectFailure", self.name)
	self:dispatchEvent({name = socketClient.EVENT_CONNECT_FAILURE})
end

return socketClient