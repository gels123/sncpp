-------fixtest.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
    gLog.i("=====fixtest begin")
    print("=====fixtest begin")
    --
    --local simAgent = require("simAgent").new()
    --simAgent:connectLogin()
    --
    --local agentPoolCenter = require("agentPoolCenter"):shareInstance()
    --gLog.dump(agentPoolCenter, "===sdfdf==agentPoolCenter=", 10)

    --local consistentHash = require("consistentHash")
    --local hash = consistentHash.new()
    --hash:addPhysicalNode(1001)
    --hash:addPhysicalNode(1002)
    --gLog.i("fixtest===", hash:getObjectNode(61312))
    --gLog.i("fixtest===", hash:getObjectNode(61376))


    local agentCenter = require("agentCenter"):shareInstance()
    local protos = {
        {
            cmd = "notifyTest1",
            msg = {
                num = 100,
                str = "sdfadfads100__[]sd.?",
                array = {{x=1,y=2,}, {x=11,y=2,}, {x=111,y=2,}, {x=11111,y=2,}, {x=111111,y=2,}, {x=1,y=12,}, {x=1,y=112,}, {x=1,y=11112,}, {x=1,y=111112,}}
            },
        },
        {
            cmd = "notifyTest2",
            msg = {
                num = 200,
                str = "sdfadfads200__@4343&&**(",
                array = {
                    {
                        uid  = 1201,
                        kid =1,
                        sKid =1,
                        iconId =1,
                        lv =1,
                        name = "lord23333",
                    },
                    {
                        uid  = 1202,
                        kid =1,
                        sKid =1,
                        iconId =2,
                        lv =2,
                        name = "lord54656",
                    },
                }
            },
        },
        {
            cmd = "notifyTest3",
            msg = {
                num = 200,
                str = "sdfadfads200__@4343&&**(",
                isOk= true,
            },
        },
        {
            cmd = "notifyTest4",
            msg = {
                num = 200,
                str = "sdfadfads200__@4343&&**(",
                array= {
                    {
                        uniqueId =1,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =2,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =3,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =4,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =5,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =6,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =7,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =8,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =9,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =10,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =11,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =12,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =13,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =14,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =15,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =16,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =17,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =18,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =19,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =20,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =21,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =22,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =23,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =24,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =25,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =26,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =27,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =28,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =29,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =30,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =31,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =101,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =102,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =103,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =104,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =105,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =106,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =107,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =108,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =109,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =110,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =111,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =112,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =113,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =114,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =115,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =116,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =117,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =118,
                        itemId =101,
                        count =1,
                    },
                    {
                        uniqueId =119,
                        itemId =101,
                        count =1,
                    }
                },
            },
        },
        {
            cmd = "notifyTest5",
            msg = {
                num = 200,
                str = "sdfadfads200__@4343&&**(",
                array= {
                    [0] ={
                        tp  = 0,
                        curCap = 50,
                        items = {
                            {
                                uniqueId =1,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =2,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =3,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =4,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =5,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =6,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =7,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =8,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =9,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =10,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =11,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =12,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =13,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =14,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =15,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =16,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =17,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =18,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =19,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =20,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =21,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =22,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =23,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =24,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =25,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =26,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =27,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =28,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =29,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =30,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =31,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =101,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =102,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =103,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =104,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =105,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =106,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =107,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =108,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =109,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =110,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =111,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =112,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =113,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =114,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =115,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =116,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =117,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =118,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =119,
                                itemId =101,
                                count =1,
                            }
                        }
                    },
                    [100] ={
                        tp  = 100,
                        curCap = 50,
                        items = {
                            {
                                uniqueId =10000,
                                itemId =101,
                                count =1,
                            },
                            {
                                uniqueId =20000,
                                itemId =101,
                                count =1,
                            },
                        }
                    },
                }
            },
        },
    }
    local player = agentCenter:getPlayer()
    while true do
        for i=1,2,1 do
            local rd =  svrFunc.random(1, 5)
            player:notifyMsg(protos[rd].cmd, protos[rd].msg)
        end
        skynet.sleep(1)
    end

    gLog.i("=====fixtest end")
    print("=====fixtest end")
end,svrFunc.exception)