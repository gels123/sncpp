--[[
    全局服的agent服务接口（注: global服为分布式服, 每个全局服节点有一组业务服, 根据玩家id映射全局服节点和业务服索引）
]]
local skynet = require ("skynet")
local dbconf = require ("dbconf")
local svrAddrMgr = require ("svrAddrMgr")
local svrConf = require ("svrConf")
local serverStartLib = require ("serverStartLib")
local agentLib = class("agentLib")

agentLib.serviceNum = 13 -- 注意: 需和全局服的保持一致

-- 根据id返回服务id
function agentLib:idx(id)
    return tonumber(id)%agentLib.serviceNum + 1
end

-- 获取地址(先一致性哈希确定globalnodeid,再取模)
function agentLib:getAddress(kid, id)
    local nodeid = assert(serverStartLib:hashNodeidGb(kid, id))
    if dbconf.globalnodeid and dbconf.globalnodeid == nodeid then -- global服(仅有global服配置dbconf.globalnodeid)
        return svrAddrMgr.getSvr(svrAddrMgr.agentSvrGlobal, dbconf.globalnodeid, self:idx(id))
    else -- 非global服
        return svrConf:getSvrProxy(nodeid, svrAddrMgr.getSvrName(svrAddrMgr.agentSvrGlobal, nodeid, self:idx(id)))
    end
end

-- call调用
function agentLib:call(kid, id, ...)
    return skynet.call(self:getAddress(kid, id), "lua", ...)
end

-- send调用
function agentLib:send(kid, id, ...)
    skynet.send(self:getAddress(kid, id), "lua", ...)
end

return agentLib
