--[[
	邮件工具类
]]
local mailConf = require "mailConf"
local mailUtils = class("mailUtils")

-- 邮件是否有效
function mailUtils.isMailAvailabe(expiretime)
	if "number" == type(expiretime) then
		if expiretime <= 0 then
			return true
		end
		if expiretime < svrFunc.systemTime() then
			return true
		end
	end
end

return mailUtils
