--[[
    状态机
]]
local fsmStateMachine = class("fsmStateMachine")

function fsmStateMachine:ctor(conf)
    self.states = {}    --状态
    self.event = {}     --事件
    self.curState = nil --当前状态

    if conf then
        self.states = conf.states
        for k,v in pairs(self.states) do
            self.event[k] = {}
        end
        self.curState = conf.curState
        assert(self.event[self.curState], "fsmStateMachine:ctor error: curState invalid!")
    end
end

function fsmStateMachine:addTransition(before, event, after)
    if self.event[before] then
        if self.event[before][event] then 
            asset("fsmStateMachine:addTransition error: event already be added!")
        else
            self.event[before][event] = after
        end
    else
        asset("fsmStateMachine:addTransition error: before not exist!")
    end
end

function fsmStateMachine:stateTransition(event, ...)
    assert(self.curState)
    local after = self.event[self.curState] and self.event[self.curState][event]
    if after then
        -- respont to this event
        gLog.d("fsmStateMachine:stateTransition ok: reponse to event", self.curState, event, after)
        if self.states[self.curState].exit then
            self.states[self.curState]:exit(...)
        end
        self.curState = after
        if self.states[self.curState].enter then
            self.states[self.curState]:enter(...)
        end
    else
        -- no related event
        gLog.e("fsmStateMachine:stateTransition error: no reponse to event", self.curState, event)
    end
end

return fsmStateMachine