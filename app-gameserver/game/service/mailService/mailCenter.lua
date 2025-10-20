--[[
    邮件服务中心
]]
local skynet = require "skynet"
local dbconf = require "dbconf"
local mailConf = require "mailConf"
local svrFunc = require "svrFunc"
local gLog = require "newLog"
local serviceCenterBase = require("serviceCenterBase2")
local mailCenter = class("mailCenter", serviceCenterBase)

-- 初始化
function mailCenter:init(kid, idx)
    gLog.i("mailCenter:init begin=", kid, idx)
    mailCenter.super.init(self, kid)

    -- 索引
    self.idx = idx
    -- 计时器管理器
    self.timerMgr = require("timerMgr").new(handler(self, self.timerCallback), self.myTimer)
    -- 邮件数据管理
    self.mailDataMgr = require("mailDataMgr").new()
    -- 玩家邮件管理
    self.playerMailMgr = require("playerMailMgr").new()
    -- 共享邮件管理
    self.shareMailMgr = require("shareMailMgr").new()

    -- 邮件数据初始化
    self.mailDataMgr:init()
    -- 共享邮件初始化
    self.shareMailMgr:init()

    gLog.i("mailCenter:init end=", kid, idx)
    return true
end

-- 登陆
function mailCenter:login(uid)
    gLog.d("mailCenter:login", uid)
    return self.playerMailMgr:login(uid)
end

-- checkin
function mailCenter:checkin(uid)
    gLog.d("mailCenter:checkin", uid)
    return self.playerMailMgr:checkin(uid)
end

-- 登出
function mailCenter:afk(uid)
    gLog.d("mailCenter:afk", uid)
    self.playerMailMgr:afk(uid)
end

-- 登出
function mailCenter:logout(uid)
    gLog.d("mailCenter:logout", uid)
    self.playerMailMgr:logout(uid)
end

-- 计时器回调
function mailCenter:timerCallback(data)
    if dbconf.DEBUG then
        gLog.d("mailCenter:timerCallback data=", data.id, data.timerType)
    end
    local id, timerType = data.id, data.timerType
    if self.timerMgr:hasTimer(id, timerType) then
        if timerType == mailConf.timerType.shareExpire then -- 共享邮件过期
            self.shareMailMgr:queue(function()
                self.shareMailMgr:updateExpireTimer()
            end)
        elseif timerType == mailConf.timerType.playerExpire then -- 玩家邮件过期
            local playerMail = self:getPlayerMail(id)
            if playerMail then
                self.playerMailMgr:queue(id, function()
                    playerMail:updateExpireTimer()
                end)
            end
        elseif timerType == mailConf.timerType.playerRelease then -- 玩家邮件释放
            self.playerMailMgr:releasePlayerMail(id)
        elseif timerType == mailConf.timerType.mailRelease then -- 邮件数据释放
            self.mailDataMgr:release(id)
        -- elseif timerType == mailConf.timerType.mailExpire then -- 邮件数据过期
        --     self.mailDataMgr:onExpireMailCallback()
        else
            gLog.w("mailCenter:timerCallback ignore", id, timerType)
        end
    else
        gLog.w("mailCenter:timerCallback ignore", id, timerType)
    end
end

-- 根据玩家上次读取的邮件ID, 导入新的共享邮件
function mailCenter:loadShareMail(uid, lastMid, castleLv, isNewUsr)
    gLog.d("mailCenter:loadShareMail=", uid, lastMid, castleLv, isNewUsr)
    return self.playerMailMgr:queue(uid, function()
        return self.shareMailMgr:loadMail(lastMid, castleLv, isNewUsr)
    end)
end

-- 发送邮件
function mailCenter:sendMail(sender, receivers, mailtype, settype, cfgid, content, expiretime)
    if dbconf.DEBUG then
        gLog.d("mailCenter:sendMail sender=", sender, "mailtype=", mailtype, "settype=", settype, "cfgid=", cfgid, "expiretime=", expiretime, "receivers=", table2string(receivers), "content=", table2string(content))
    end
    -- 检查发送者
    sender = sender or 0
    if type(sender) ~= "number" then
        gLog.e("mailCenter:sendMail error1", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查收件人
    if not receivers or not next(receivers) then
        gLog.e("mailCenter:sendMail error2", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    for _,uid in pairs(receivers) do
        if not uid or uid <= 0 then
            gLog.e("mailCenter:sendMail error3", sender, mailtype, settype, cfgid, "uid=", uid)
            return false, gErrDef.Err_MAIL_CREATE
        end
    end
    -- 检查邮件类型
    if mailtype ~= mailConf.mailTypes.typeNormal then
        gLog.e("mailCenter:sendMail error4", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查集合类型
    if not settype or settype <= 0 or not mailConf.setTypesRev[settype] then
        gLog.e("mailCenter:sendMail error5", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查配置id
    if not cfgid or cfgid <= 0 then
        gLog.e("mailCenter:sendMail error5", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 创建邮件
    local ok, mailData = self.mailDataMgr:create(sender, receivers, mailtype, settype, cfgid, content, expiretime or mailConf.expiretime, 0)
    if not ok then
        gLog.e("mailCenter:sendMail error6", sender, mailtype, settype, cfgid)
        return false, mailData or gErrDef.Err_SERVICE_EXCEPTION
    end
    local mid = mailData:getAttr("mid")
    gLog.i("mailCenter:sendMail success=", sender, mailtype, settype, cfgid, "mid=", mid, cfgid)
    -- 是否有人成功添加邮件
    ok = false
    -- 非共享邮件
    for _, uid in pairs(receivers) do
        xpcall(function()
            local r, code = self.playerMailMgr:addNewMail(uid, mid, mailtype, settype, cfgid, mailData:hasExtra(), content and content.brief, mailData:getAttr("expiretime"), false)
            if not r then
                gLog.e("mailCenter:sendMail error7", sender, mailtype, settype, "uid=", uid, mid, "cfgid=", cfgid, code)
            else
                gLog.i("mailCenter:sendMail do=", sender, mailtype, settype, "uid=", uid, mid, "cfgid=", cfgid)
                ok = true
            end
        end, svrFunc.exception)
    end
    -- 无一人成功添加邮件, 删除邮件数据
    if not ok then
        self.mailDataMgr:remove(mid, nil, true)
    end
    return ok
end

-- 发送共享邮件
function mailCenter:sendShareMail(sender, mailtype, settype, cfgid, content, expiretime, castleLv, logoutTime, isNewUsr)
    if dbconf.DEBUG then
        gLog.d("mailCenter:sendShareMail sender=", sender, "mailtype=", mailtype, "settype=", settype, "cfgid=", cfgid, "expiretime=", expiretime, "castleLv=", castleLv, "logoutTime=", logoutTime, "isNewUsr=", isNewUsr, "content=", table2string(content))
    end
    -- 检查发送者
    sender = sender or 0
    if type(sender) ~= "number" then
        gLog.e("mailCenter:sendShareMail error1", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查邮件类型
    if mailtype ~= mailConf.mailTypes.typeNormal then
        gLog.e("mailCenter:sendShareMail error2", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查集合类型
    if not settype or settype <= 0 or not mailConf.setTypesRev[settype] then
        gLog.e("mailCenter:sendShareMail error3", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 检查配置id
    if not cfgid or cfgid <= 0 then
        gLog.e("mailCenter:sendShareMail error4", sender, mailtype, settype, cfgid)
        return false, gErrDef.Err_MAIL_CREATE
    end
    -- 创建邮件
    local ok, mailData = self.mailDataMgr:create(sender, nil, mailtype, settype, cfgid, content, expiretime or mailConf.expiretime, 1)
    if not ok then
        gLog.e("mailCenter:sendShareMail error5", sender, mailtype, settype, cfgid)
        return false, mailData or gErrDef.Err_SERVICE_EXCEPTION
    end
    local mid = mailData:getAttr("mid")
    gLog.i("mailCenter:sendShareMail success=", sender, mailtype, settype, cfgid, "mid=", mid)
    --创建共享邮件, 区分于普通邮件
    self.shareMailMgr:createMail(mid, castleLv, logoutTime, isNewUsr, expiretime or mailConf.expiretime)
    --在线玩家, 需立即发送邮件
    local onlines = self.playerMailMgr:getUserOnline()
    if next(onlines) then
        for uid,_ in pairs(onlines) do
            xpcall(function()
                local ok_, code = self.playerMailMgr:addNewMail(uid, mid, mailtype, settype, cfgid, mailData:hasExtra(), content and content.brief, mailData:getAttr("expiretime"), true)
                if not ok_ then
                    gLog.i("mailCenter:sendShareMail error7", sender, mailtype, settype, cfgid, "mid=", mid, uid, "code=", code)
                else
                    gLog.i("mailCenter:sendShareMail do=", sender, mailtype, settype, cfgid, "mid=", mid, uid)
                end
            end, svrFunc.exception)
        end
    end
    return true
end

-- 请求邮件封面数据
function mailCenter:reqCovers(uid)
    gLog.d("mailCenter:reqCovers", uid)
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return playerMail:reqCovers()
    end
end

-- 请求邮件简要信息
function mailCenter:reqMailBrief(uid, settype, begin, over)
    gLog.d("mailCenter:reqMailBrief", uid, settype, begin, over)
    if not uid or not settype or not begin or not over then
        return
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return playerMail:reqMailBrief(settype, begin, over)
    end
end

-- 请求邮件详细信息/查看分享邮件
function mailCenter:reqMailDetail(uid, settype, mid, flag)
    gLog.d("mailCenter:reqMailDetail", uid, settype, mid, flag)
    if not uid or not mid then
        gLog.d("mailCenter:reqMailDetail error", uid, settype, mid, flag)
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reqMailDetail(settype, mid, flag)
        end)
    end
end

-- 请求删除邮件
function mailCenter:reqDelMail(uid, settype, mids)
    gLog.d("mailCenter:reqDelMail", uid, settype, #mids)
    if not uid or not mids then
        gLog.d("mailCenter:reqDelMail error", uid, settype, #mids)
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reqDelMail(settype, mids)
        end)
    end
end

-- 请求一键删除邮件
function mailCenter:reqDelMailOneKey(uid, settype)
    gLog.d("mailCenter:reqDelMailOneKey", uid, settype)
    if not uid or not settype then
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reqDelMailOneKey(settype)
        end)
    end
end

-- 请求领取邮件附件
function mailCenter:reqGetMailExtra(uid, settype, mid)
    gLog.d("mailCenter:reqGetMailExtra", uid, settype, mid)
    if not uid or not mid then
        gLog.d("mailCenter:reqGetMailExtra error", uid, settype, mid)
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reqGetMailExtra(settype, mid)
        end)
    end
end

-- 请求一键领取邮件附件
function mailCenter:reqGetMailExtraOneKey(uid, settypes)
    gLog.d("mailCenter:reqGetMailExtraOneKey", uid, settypes)
    if not uid or not settypes then
        gLog.d("mailCenter:reqGetMailExtraOneKey error", uid, settypes)
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reqGetMailExtraOneKey(settypes)
        end)
    end
end

-- 请求收藏邮件
function mailCenter:reCollectMail(uid, settype, mid)
    gLog.d("mailCenter:reCollectMail", uid, settype, mid)
    if not uid or not mid then
        return nil, gErrDef.Err_ILLEGAL_PARAMS
    end
    local playerMail = self.playerMailMgr:getPlayerMail(uid)
    if playerMail then
        return self.playerMailMgr:queue(uid, function()
            return playerMail:reCollectMail(settype, mid)
        end)
    end
end

return mailCenter