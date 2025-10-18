local skynet = require("skynet")
local respondCtrl = {}

respondCtrl.cmdData = {}
respondCtrl.cmdTotalRank = {}
respondCtrl.cmdAveRank = {}
respondCtrl.cmdMaxRank = {}

------------------service----------------
-- 向客户端直接回应当前的请求, 此处要求一个 lua table 作为参数
-- 本函数将 lua table 编码成 json 串 
function respondCtrl.respondtoclient(msg)
    local agentCenter = require("agentCenter"):shareInstance()
    local player = agentCenter:getPlayer()
    player:sendMsg(msg)
    
    respondCtrl.respondtocmd(msg)
end

-- 回应当前的请求
function respondCtrl.respondtocmd(...)
	skynet.ret(skynet.pack(...))
end

-- 消息返回
-- 客户端发上来的req中会有一个key：source = "c"
function respondCtrl.respond(...)
    local req = ...
    if dbconf.DEBUG then
        gLog.dump(req, "respondCtrl.respond req:", 10)
    end
    if "table" == type(req) and "c" == req.source then
        respondCtrl.respondtoclient(req)
    else
        respondCtrl.respondtocmd(...)
    end
end

-- 构造一个针对当前服务请求的延迟发送的回应闭包, 可以在后续任务中
-- 再处理这个回应
function respondCtrl.createCmdResponseClosure()
    return skynet.response()
end

-- 延时向 service 发送通知
function respondCtrl.notifyservice(responseclosure, ...)
    responseclosure(true, ...)
end

-- 构造一个针对当前客户端请求的延迟发送的回应闭包, 可以在后续任务中
-- 再处理这个回应
function respondCtrl.createMsgResponseClosure( )
    return skynet.response(function(m) return tostring(m) end)
end

function respondCtrl.statisCmd(nCmd, nSubcmd, nSize)
    nSize = nSize or 0
    local key = tostring(nCmd) .. "_" .. tostring(nSubcmd)
    if respondCtrl.cmdData[key] then
        local maxSize = respondCtrl.cmdData[key].maxSize
        local aveSize = 0
        local count = respondCtrl.cmdData[key].count
        local totalSize = respondCtrl.cmdData[key].totalSize
        if nSize > maxSize then
            maxSize = nSize
            respondCtrl.cmdData[key].maxSize = maxSize
        end
        totalSize = totalSize + nSize
        count = count + 1
        aveSize = svrFunc.getIntPart(totalSize/count)
        respondCtrl.cmdData[key].aveSize = aveSize
        respondCtrl.cmdData[key].totalSize = totalSize
        respondCtrl.cmdData[key].count = count
    else
        respondCtrl.cmdData[key] = {
            maxSize = nSize,
            count = 1,
            totalSize = nSize,
            aveSize = nSize,
        }
    end
end

function respondCtrl.getCmdData()
    local data = {}
    respondCtrl.cmdTotalRank = {}
    respondCtrl.cmdAveRank = {}
    respondCtrl.cmdMaxRank = {}
    for key,v in pairs(respondCtrl.cmdData) do
        v.cmd = key
        table.insert(respondCtrl.cmdTotalRank,v)
        table.insert(respondCtrl.cmdAveRank,v)
        table.insert(respondCtrl.cmdMaxRank,v)
    end
    table.sort(respondCtrl.cmdTotalRank, function (A,B)
        if A.totalSize > B.totalSize then
            return true
        else
            return false
        end
    end)
    table.sort(respondCtrl.cmdAveRank, function (A,B)
        if A.aveSize > B.aveSize then
            return true
        else
            return false
        end
    end)
    table.sort(respondCtrl.cmdMaxRank, function (A,B)
        if A.maxSize > B.maxSize then
            return true
        else
            return false
        end
    end)
    data.cmdTotalRank = respondCtrl.cmdTotalRank
    data.cmdAveRank = respondCtrl.cmdAveRank
    data.cmdMaxRank = respondCtrl.cmdMaxRank
    gLog.dump(data, "respondCtrl.getCmdData data=", 10)
    return data
end

-- 常用的正常返回
-- req: table
-- ok: 正确或错误，true or false
-- 如果ok = true, ... 为返回的数据
-- 如果ok = false, ... 为错误码和数据（可选）
function respondCtrl.commonCmdRsp(req, ok, ...)
    req = req or {}
    if ok then
        req.err = gErrDef.Err_OK
        if ... then
            req.data = ...
        end
    else
        local err, data = ...
        req.err = err
        if data then
            req.data = data
        end
    end
    respondCtrl.respond(req)
end

return respondCtrl