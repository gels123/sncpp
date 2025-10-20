--[[
	pvp战场网关服务中心
]]
local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local iSockServer =  require "iSockServer"
local gatepvpCenter = class("gatepvpCenter", iSockServer)

-- 获取单例
local instance = nil  
function gatepvpCenter.shareInstance(cc)
    if not instance then
        instance = cc.new()
    end
    return instance
end

-- 构造
function gatepvpCenter:ctor()
	self.super.ctor(self)
	-- 随机种子
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
end

-- 内存回收
function gatepvpCenter:__gc()
	gLog.i("gatepvpCenter:__gc")
	if self.sock then
		socketdriver.close(self.sock)
	end
end

-- 杀死服务
function gatepvpCenter:kill()
	gLog.i("== gatepvpCenter:kill ==")
    skynet.exit()
end

-- 初始化
function gatepvpCenter:init(kid, mode, port)
	gLog.i("== gatepvpCenter:init begin ==", kid, mode, port)
	self.super.init(self, mode, port)
    self.kid = kid
    gLog.i("== gatepvpCenter:init end ==", kid, mode, port)
	return true
end

-- 分发服务端调用
function gatepvpCenter:dispatchCmd(session, source, cmd, ...)
    --gLog.d("gatepvpCenter:dispatchCmd", session, source, cmd, ...)
    local func = instance and instance[cmd]
    if func then
        if 0 == session then
            xpcall(func, svrFunc.exception, self, ...)
        else
            self:ret(xpcall(func, svrFunc.exception, self, ...))
        end
    else
        self:ret()
        gLog.e("gatepvpCenter:dispatchCmd error: cmmand not found:", cmd, ...)
    end
end

-- 返回数据
function gatepvpCenter:ret(_, ...)
    skynet.ret(skynet.pack(...))
end

return gatepvpCenter