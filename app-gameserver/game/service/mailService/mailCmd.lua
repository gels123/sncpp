--[[
	邮件指令
]]
local skynet =  require "skynet"
local mailConf = require "mailConf"
local mailLib = require "mailLib"
local agentCenter = require("agentCenter"):shareInstance()
local clientCmd = require "clientCmd"

-- 请求邮件封面数据
function clientCmd.reqCovers(player, req)
    gLog.dump(req, "clientCmd.reqCovers uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        local covers = mailLib:call(player:getKid(), player:getUid(), "reqCovers", player:getUid())
        if not covers then
            code = gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.covers = covers
    until true

    ret.code = code
    return ret
end

-- 请求邮件简要信息 reqMailBrief settype=1 begin=1 over=20
function clientCmd.reqMailBrief(player, req)
    gLog.dump(req, "clientCmd.reqMailBrief uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settype or not mailConf.setTypesRev[req.settype] or not req.begin or req.begin <= 0 or not req.over or req.over <= 0 or req.begin > req.over then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local mails, cover, autoViewMids = mailLib:call(player:getKid(), player:getUid(), "reqMailBrief", player:getUid(), req.settype, req.begin, req.over)
        if not mails then
            code = cover or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.settype = req.settype
        ret.begin = req.begin
        ret.over = req.over
        ret.mails = mails
        ret.cover = cover
        ret.autoViewMids = autoViewMids
    until true

    ret.code = code
    return ret
end

-- 请求邮件详细信息/查看分享邮件 reqMailDetail settype=1 mid=5
function clientCmd.reqMailDetail(player, req)
    gLog.dump(req, "clientCmd.reqMailDetail uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settype or not mailConf.setTypesRev[req.settype] or not req.mid then
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local uid = (req.shareUid and req.shareUid > 0 and req.shareUid) or player:getUid()
        local detail, cover, brief, cfgid = mailLib:call(player:getKid(), player:getUid(), "reqMailDetail", uid, req.settype, req.mid, (req.shareUid and req.shareUid > 0))
        if not detail then
            code = cover or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.settype = req.settype
        ret.mid = req.mid
        ret.shareUid = req.shareUid
        ret.detail = detail
        ret.cover = cover
        ret.brief = brief
        ret.cfgid = cfgid
    until true

    ret.code = code
    return ret
end

-- 请求删除邮件 reqDelMail settype=1 mids={5}
function clientCmd.reqDelMail(player, req)
    gLog.dump(req, "clientCmd.reqDelMail uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settype or not mailConf.setTypesRev[req.settype] or not req.mids or not next(req.mids) then
            gLog.d("clientCmd.reqDelMail err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local mids, cover = mailLib:call(player:getKid(), player:getUid(), "reqDelMail", player:getUid(), req.settype, req.mids)
        if not mids then
            gLog.d("clientCmd.reqDelMail err2", player:getUid())
            code = gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.settype = req.settype
        ret.mids = mids
        ret.cover = cover
    until true

    ret.code = code
    return ret
end

-- 请求一键删除邮件 reqDelMailOneKey settype=1
function clientCmd.reqDelMailOneKey(player, req)
    gLog.dump(req, "clientCmd.reqDelMailOneKey uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settype or not mailConf.setTypesRev[req.settype] then
            gLog.d("clientCmd.reqDelMailOneKey err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local mids, cover = mailLib:call(player:getKid(), player:getUid(), "reqDelMailOneKey", player:getUid(), req.settype)
        if not mids then
            gLog.d("clientCmd.reqDelMailOneKey err2", player:getUid())
            code = gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.settype = req.settype
        ret.mids = mids
        ret.cover = cover
    until true

    ret.code = code
    return ret
end

-- 请求领取邮件附件 reqGetMailExtra settype=1 mid=5
function clientCmd.reqGetMailExtra(player, req)
    gLog.dump(req, "clientCmd.reqGetMailExtra uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.mid or req.mid <= 0 or not req.settype or not mailConf.setTypesRev[req.settype] then
            gLog.d("clientCmd.reqGetMailExtra err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local extra, cover = mailLib:call(player:getKid(), player:getUid(), "reqGetMailExtra", player:getUid(), req.settype, req.mid)
        if not extra then
            gLog.i("clientCmd.reqGetMailExtra err2 code=", extra)
            code = extra or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        -- 增加附件奖励
        if extra and next(extra) then
            svrFunc.sendReward(player, extra)
        end
        ret.settype = req.settype
        ret.mid = req.mid
        ret.cover = cover
        ret.extra = extra
    until true

    ret.code = code
    return ret
end

-- 请求一键领取邮件附件 reqGetMailExtraOneKey settypes={1,2}
function clientCmd.reqGetMailExtraOneKey(player, req)
    gLog.dump(req, "clientCmd.reqGetMailExtraOneKey uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settypes or not next(req.settypes) then
            gLog.d("clientCmd.reqGetMailExtraOneKey err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        for _,settype in pairs(req.settypes) do
            if not mailConf.setTypesRev[settype] then
                gLog.d("clientCmd.reqGetMailExtraOneKey err2", player:getUid())
                code = gErrDef.Err_ILLEGAL_PARAMS
                break
            end
        end
        local mids, extras, covers = mailLib:call(player:getKid(), player:getUid(), "reqGetMailExtraOneKey", player:getUid(), req.settypes)
        if not mids then
            gLog.i("clientCmd.reqGetMailExtraOneKey err3 code=", extras)
            code = extras or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        -- 增加附件奖励
        if extras and next(extras) then
            svrFunc.sendReward(player, extras)
        end
        ret.mids = mids
        ret.extras = extras
        ret.covers = covers
    until true

    ret.code = code
    return ret
end

-- 请求收藏邮件 reCollectMail mid=59
function clientCmd.reCollectMail(player, req)
    gLog.dump(req, "clientCmd.reCollectMail uid="..player:getUid())
    local ret = {}
    local code = gErrDef.Err_OK

    repeat
        if not req.settype or not mailConf.setTypesRev[req.settype] or not req.mid or req.mid <= 0 then
            gLog.d("clientCmd.reCollectMail err1", player:getUid())
            code = gErrDef.Err_ILLEGAL_PARAMS
            break
        end
        local mid, covers = mailLib:call(player:getKid(), player:getUid(), "reCollectMail", player:getUid(), req.settype, req.mid)
        if not mid then
            gLog.d("clientCmd.reCollectMail err2", player:getUid())
            code = covers or gErrDef.Err_SERVICE_EXCEPTION
            break
        end
        ret.mid = mid
        ret.settype = req.settype
        ret.covers = covers
    until true

    ret.code = code
    return ret
end