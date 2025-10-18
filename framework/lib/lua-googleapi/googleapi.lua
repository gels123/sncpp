--[[
    lua版本谷歌API
]]
local luagoogleapi = require("luagoogleapi")
local googleapi = class("googleapi")

-- 初始化
function googleapi:doInit(fileName, fcmfileName)
    return luagoogleapi.doInit(fileName, fcmfileName)
end

-- 验证订单状态
function googleapi:doVerify(packageName, productId, purchaseToken)
    if packageName and productId and purchaseToken then
        return luagoogleapi.doVerify(packageName, productId, purchaseToken)
    end
end

-- 给单个主题推送消息
function googleapi:sendMsgToTopic(topic, title, body)
    if topic and topic ~= "" and title and body then
        return luagoogleapi.sendMsgToTopic(topic, title, body)
    end
end

-- 给单个玩家推送消息
function googleapi:sendMsgToToken(token, title, body)
    if token and token ~= "" and title and body then
        return luagoogleapi.sendMsgToToken(token, title, body)
    end
end

-- 多个玩家订阅单个主题
function googleapi:subscribe(topic, tokens)
    if topic and topic ~= "" and tokens and #tokens > 0 then
        return luagoogleapi.subscribe(topic, #tokens, tokens)
    end
end

-- 多个玩家订阅单个主题
function googleapi:unsubscribe(topic, tokens)
    if topic and topic ~= "" and tokens and #tokens > 0 then
        return luagoogleapi.unsubscribe(topic, #tokens, tokens)
    end
end

return googleapi