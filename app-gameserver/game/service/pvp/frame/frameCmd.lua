local skynet = require "skynet"
local frameLib = require "frameLib"
local svrFunc = require "svrFunc"
local clientCmd = require "clientCmd"

-- 请求创建战场 eg: reqCreateBattle batId="123" users={[1201]={uid=1201,camp=0,}, [1202]={uid=1202,camp=1,}}
function clientCmd.reqCreateBattle(user, req)
    --gLog.dump(req, "clientCmd.reqCreateBattle uid="..tostring(user:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.batId or not req.users then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local ok, code2 = frameLib:call(user:getKid(), req.batId, "createBattle", req.batId, req.users, req.rate, req.time)
        if not ok then
            code = code2 or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.batId = req.batId
        ret.info = code2
    until true

    ret.code = code
    return ret
end

-- 请求心跳
function clientCmd.reqPvpHeartbeat(user, req)
    --gLog.dump(req, "clientCmd.reqPvpHeartbeat uid="..tostring(user:getUid()))
    local frameCenter = require("frameCenter"):shareInstance()
    frameCenter.timerMgr:updateTimer(user:getUid(), gPvpTimerType.heartbeat, svrFunc.systemTime()+gPvpHeartbeat)
    return {time = svrFunc.systemTime(),}
end

-- 请求更改心跳开关
function clientCmd.reqPvpHeartbeatSwitch(user, req)
    --gLog.dump(req, "clientCmd.reqPvpHeartbeatSwitch uid="..tostring(user:getUid()))
    local frameCenter = require("frameCenter"):shareInstance()
    if req.close then
        frameCenter.timerMgr:updateTimer(user:getUid(), gPvpTimerType.heartbeat, nil)
    else
        frameCenter.timerMgr:updateTimer(user:getUid(), gPvpTimerType.heartbeat, svrFunc.systemTime()+gPvpHeartbeat)
    end
    return {code = gErrDef.Err_OK}
end

-- 请求准备完成 eg: reqPrepare batId=123
function clientCmd.reqPrepare(user, req)
    --gLog.dump(req, "clientCmd.reqPrepare uid="..tostring(user:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.batId then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local ok, code2 = frameLib:call(user:getKid(), req.batId, "reqPrepare", req.batId, user:getUid())
        if not ok then
            code = code2 or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.batId = req.batId
    until true

    ret.code = code
    return ret
end

-- 请求加载场景完成 eg: reqLoad batId=123
function clientCmd.reqLoad(user, req)
    --gLog.dump(req, "clientCmd.reqLoad uid="..tostring(user:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.batId then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local ok, code2 = frameLib:call(user:getKid(), req.batId, "reqLoad", req.batId, user:getUid())
        if not ok then
            code = code2 or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.batId = req.batId
    until true

    ret.code = code
    return ret
end

-- 请求退出战场
function clientCmd.reqLeave(user, req)
    --gLog.dump(req, "clientCmd.reqLeave uid="..tostring(user:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.batId then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local ok, code2 = frameLib:call(user:getKid(), req.batId, "reqLeave", req.batId, user:getUid())
        if not ok then
            code = code2 or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.batId = req.batId
    until true

    ret.code = code
    return ret
end

-- 请求提交帧指令 eg: reqCommitCmd batId="123" cmd={f=1,tp=1,str="1234567890"}
function clientCmd.reqCommitCmd(user, req)
    --gLog.dump(req, "clientCmd.reqCommitCmd uid="..tostring(user:getUid()))
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.batId or not req.cmd or not req.cmd.tp then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local ok, code2 = frameLib:call(user:getKid(), req.batId, "reqCommitCmd", req.batId, user:getUid(), req.cmd)
        if not ok then
            code = code2 or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.batId = req.batId
    until true

    ret.code = code
    return ret
end

return clientCmd

