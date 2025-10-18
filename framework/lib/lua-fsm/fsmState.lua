--[[
    状态
]]
local fsmState = class("fsmState")

function fsmState:ctor(conf)
    if conf then
        --进入状态
        if type(conf.enter) == "function" then
            self.enter = conf.enter
        end
        --更新状态
        if type(conf.update) == "function" then
            self.update = conf.update
        end
        --离开状态
        if type(conf.exit) == "function" then
            self.exit = conf.exit
        end
    end
end

return fsmState