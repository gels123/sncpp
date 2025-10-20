--[[
	npc模块
]]
local skynet = require("skynet")
local agentCenter = require("agentCenter"):shareInstance()
local player = agentCenter:getPlayer()
local eventLib = require("eventLib")
local baseCtrl = require("baseCtrl")
local lordCtrl = class("lordCtrl", baseCtrl)

-- 构造
function lordCtrl:ctor(uid)
    self.super.ctor(self, uid)

    self.module = "lordinfo" -- 数据表名
end

-- 初始化
function lordCtrl:init()
    if self.bInit then
        return
    end
    -- 设置已初始化
    self.bInit = true
    self.data = self:queryDB()
    if "table" ~= type(self.data) then
        self.data = self:defaultData(player:getUid(), player:getKid())
        self:updateDB()
    end
    gLog.dump(self.data, "lordCtrl:init self.data=")
    -- 注册事件
    self.hLogin = player:registerEvent(gEventDef.Event_UidLogin, "onLogin", self)
    self.hAidInfo = eventLib:registerEvent(gEventDef.Event_AidInfo, self:getAid(), "onAidInfo", self)
end

-- 默认数据
function lordCtrl:defaultData(uid, kid)
    return {
        uid = uid or 0, 	-- 玩家ID
        kid = kid or 0, 	-- 玩家当前王国ID
        sKid = kid or 0, 	-- 玩家原始王国ID
        iconId = 0, 		-- 玩家头像
        name = "", 			-- 玩家昵称
        aid = 0,			-- 玩家联盟ID
        ip = "",            -- IP
        country = "",       -- 国家/语言
        loginCnt = 1,       -- 登录次数
    }
end

-- 获取初始化数据
function lordCtrl:getInitData()
    return self.data
end

function lordCtrl:logout()
    if self.hLogin then
        player:unregisterEvent(self.hLogin)
        self.hLogin = nil
    end
    if self.hAidInfo then
        eventLib:unregisterEvent(self.hAidInfo)
        self.hAidInfo = nil
    end
    -- require("eventCtrl").dump()
end

function lordCtrl:getAid()
    return self.data.aid or 0
end

-- 处理登录事件
function lordCtrl:onLogin(event, params)
    -- gLog.dump(event, "lordCtrl:onLogin event=")
    self.data.loginCnt = self.data.loginCnt + 1
    self:updateDB()
end

-- 处理联盟信息变化事件
function lordCtrl:onAidInfo(event)
    gLog.dump(event, "lordCtrl:onAidInfo event=")

end

-- 请求创建角色
function lordCtrl:reqCreateNpc(info)
    -- if not info.npcId then
    --     info.npcId = self:genNpcId()
    -- end
    -- -- 检查npcId是否重复
    -- if self:getNpc(info.npcId) then
    --     gLog.w("lordCtrl:reqCreateNpc error1", player:getUid(), info.npcId)
    --     return false, gErrDef.Err_LORD_CREATE_NPC_REPEAT
    -- end
    -- -- 非初始npc需额外检查
    -- if info.npcId ~= gNpcDefaultID then
    --     -- 检查最大npc数量
    --     if self:getNpcNum() >= self:getMaxNpcNum() then
    --         gLog.w("lordCtrl:reqCreateNpc error2", player:getUid(), info.npcId)
    --         return false, gErrDef.Err_LORD_CREATE_NPC_LIMIT
    --     end
    --     -- 消耗道具
    -- end
    -- -- 创角npc
    -- if not self.data.npcs then
    --     self.data.npcs = {}
    -- end
    -- info = self:defaultNpcData(info)
    -- local npc = require("buffCell").new(info)
    -- self.data.npcs[info.npcId] = npc
    -- -- 存库
    -- self:updateDB()

    -- return true, npc:getData()
end

return lordCtrl
