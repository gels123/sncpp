--[[
    Agent热更样例, 注意合并前一次的热更代码
        用法：
            log fixAgent fixAgentDemo
        注意：
            1. 热更脚本的路径必须为game/service/testService, 见实现player:doHotFix()
            2. 如本热更脚本存在迭代, 需把之前的热更内容拷贝过来
            3. 每个热更点最好是skynet.fork()中处理, 以免流程报错导致别的热更点中断
--]]
local skynet = require("skynet")
local sharedataLib = require("sharedataLib")
local svrFunc = require("svrFunc")
local fixAgent = {}

function fixAgent.hotFix()
    local agentCenter = require("agentCenter"):shareInstance()
    local player = agentCenter:getPlayer()
    gLog.i("fixAgent.hotFix begin=", player:getUid())


    -- 登录模块热更
    skynet.fork(function()
        local f = function(loginCtrl)
            function loginCtrl:fixTest()
                return "v-2"
            end
        end
        -- 热更loginCtrl文件
        local loginCtrl = require(gModuleDef.loginModule)
        f(loginCtrl)
        -- 热更loginCtrl实例, 实例不一定存在
        local loginCtrl = player:getModule(gModuleDef.loginModule)
        if loginCtrl then
            f(loginCtrl)
        end
    end)


    gLog.i("fixAgent.hotFix end=", player:getUid())
end

return fixAgent