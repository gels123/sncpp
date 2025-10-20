-------一致性哈希稳定性测试
------- inject serverStartService game/service/testService/fixchash.lua
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
    gLog.i("=====fixchash begin")
    print("=====fixchash begin")


    local chash = require("conhash").new()
    chash:addnode(tostring("n1"), 512)
    chash:addnode(tostring("n2"), 512)
    chash:addnode(tostring("n3"), 512)

    local serviceCenter = require("serverStartCenter"):shareInstance()
    if not serviceCenter.gg then
        gLog.i("fixchash init gg")
        serviceCenter.gg = {}
    end
    local gg = serviceCenter.gg
    for i=1,10000,1 do
        local nid = tonumber(chash:lookup("uid"..i))
        if not gg[i] then
            gg[i] = nid
        elseif gg[i] ~= nid then
            gLog.e("fixchash 不稳定", i, nid, gg[i])
        end
    end
    for i=1,10000,1 do
        local nid = tonumber(chash:lookup("uid"..i))
        if not gg[i] then
            gg[i] = nid
        elseif gg[i] ~= nid then
            gLog.e("fixchash 不稳定", i, nid, gg[i])
        end
    end

    gLog.i("=====fixchash end")
    print("=====fixchash end")
end,svrFunc.exception)