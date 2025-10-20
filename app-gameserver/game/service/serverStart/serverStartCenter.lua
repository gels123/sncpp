--[[
	服务器启动服务中心
]]
local skynet = require "skynet"
local svrAddrMgr = require "svrAddrMgr"
local svrConf = require "svrConf"
local serviceCenterBase = require("serviceCenterBase")
local serverStartCenter = class("serverStartCenter", serviceCenterBase)

-- 构造
function serverStartCenter:ctor()
	serverStartCenter.super.ctor(self)
    
	-- 全局服存活列表、一致性哈希
	self.aliveGb = {}
	self.hashGb = require("conhash").new()
end

-- 初始化
function serverStartCenter:init(kid)
	gLog.i("==serverStartCenter:init begin==", kid)
	-- 王国ID
	self.kid = kid
	-- 服务器启动服务管理
    self.serverStartMgr = require("serverStartMgr").new()
    gLog.i("==serverStartCenter:init end==", kid)
end

-- 获取频道
function serverStartCenter:getChannel()
	return self.serverStartMgr:getChannel()
end

-- 获取是否所有服均已初始化好
function serverStartCenter:getIsOk()
	return self.serverStartMgr:getIsOk()
end

-- 完成初始化
function serverStartCenter:finishInit(svrName, address)
	self.serverStartMgr:finishInit(svrName, address)
end

-- 停止所有服务
function serverStartCenter:stop()
	gLog.i("serverStartCenter:stop", self.kid)
	return self.serverStartMgr:stop()
end

-- 收到信号停止所有服务
function serverStartCenter:stopSignal()
	gLog.i("serverStartCenter:stopSignal", self.kid)
	self:stop()
end

-- 加载服务器配置
function serverStartCenter:reloadConf(nodeid)
	gLog.i("serverStartCenter:reloadConf", nodeid)
	require("initDBConf"):set(true)
	-- 游戏服网关OPEN后向登录服注册网关服务代理
	local gateSvr = svrAddrMgr.getSvr(svrAddrMgr.gateSvr, nil, dbconf.gamenodeid)
	skynet.call(gateSvr, "lua", "registerGate")
	-- 若有全局服节点被移除, 需要更新一致性哈希
	local globalConf = require("initDBConf"):getGlobalConf()
	for nodeid,_ in pairs(self.aliveGb) do
		if not globalConf[nodeid] then
			self.aliveGb[nodeid] = nil
			self.hashGb:deletenode(tostring(nodeid))
		end
	end
end

-- 全局服存活检测
function serverStartCenter:checkAliveGb()
	local globalConf = require("initDBConf"):getGlobalConf()
	for k,v in pairs(globalConf) do
		local callOk, ok = pcall(function()
			local startSvr = svrConf:getSvrProxyGlobal(v.nodeid, svrAddrMgr.startSvrG)
			return skynet.call(startSvr, "lua", "getIsOk")
		end)
		--gLog.d("serverStartCenter:checkAliveGb=", v.nodeid, callOk, ok)
		if callOk and ok then
			if not self.aliveGb[v.nodeid] then
				self.aliveGb[v.nodeid] = v.nodeid
				self.hashGb:addnode(tostring(v.nodeid), 1024)
			end
		else
			if self.aliveGb[v.nodeid] then
				self.aliveGb[v.nodeid] = nil
				self.hashGb:deletenode(tostring(v.nodeid))
			end
		end
	end
	-- 间隔13s
	skynet.timeout(1300, function()
		self:checkAliveGb()
	end)
end

-- 业务ID映射全局服节点
function serverStartCenter:hashNodeidGb(id)
	return tonumber(self.hashGb:lookup(tostring(id)))
end

-- 测试服调时间(注: 调时间一般只增不减, 单位秒)
function serverStartCenter:addFakeTime(sec)
	if not dbconf.DEBUG or not dbconf.BACK_DOOR or sec < 0 then
		gLog.e("serverStartCenter:fakeTime error: not debug mode or sec < 0", sec)
		return false, "not backdoor mode or sec < 0"
	end
	if not self.fakeTime then
		self.fakeTime = require("playerDataLib"):query(self.kid, self.kid, "faketime") or {}
	end
	self.fakeTime.sec = (self.fakeTime.sec or 0) + sec
	gLog.i("serverStartCenter:addFakeTime add sec=", sec, "total sec=", self.fakeTime.sec)
	if self.fakeTime.sec ~= 0 then
		require("playerDataLib"):update(self.kid, self.kid, "faketime", self.fakeTime)
		-- redis中faketime数据不清理
		local redisLib = require("redisLib")
		redisLib:sendzRem(string.format("game:data-clear-%s", self.kid), string.format("game:%s-%s-%s", self.kid, "faketime", self.kid))
		-- 写文件
		local str = string.format("echo +%ds > ./faketime.rc", self.fakeTime.sec)
		io.popen(str)
	end
	return true
end

-- 发送共享邮件
function serverStartCenter:sendShareMail(cfgid, content)
	gLog.i("serverStartCenter:sendShareMail", cfgid, table2string(content))
	require("mailLib"):sendShareMail(self.kid, 0, cfgid, content)
	return true
end

return serverStartCenter
