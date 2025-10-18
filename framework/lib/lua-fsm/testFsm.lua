xpcall(function()

local fsmState = require("fsmState")
local fsmStateMachine = require("fsmStateMachine")

local lineState = {
    mass = 1,
    move = 2,
    stay = 3,
}

local cls = {}
function cls.enterMassState()
    gLog.d("cls.enterMassState")
end
function cls.exitMassState()
    gLog.d("cls.exitMassState")
end
function cls.enterMovingState()
    gLog.d("cls.enterMovingState")
end
function cls.exitMovingState()
    gLog.d("cls.exitMovingState")
end
function cls.enterStayState()
    gLog.d("cls.enterStayState")
end
function cls.exitStayState()
    gLog.d("cls.exitStayState")
end

local machine = fsmStateMachine.new({
    states = {
        [lineState.mass]=fsmState.new({["enter"]=cls.enterMassState,["exit"]=cls.exitMassState}),
        [lineState.move]=fsmState.new({["enter"]=cls.enterMovingState,["exit"]=cls.exitMovingState}),
        [lineState.stay]=fsmState.new({["enter"]=cls.enterStayState,["exit"]=cls.exitStayState}),
    },
    curState = lineState.mass,
})

machine:addTransition(lineState.mass, "timeout", lineState.move)
machine:addTransition(lineState.move, "timeout", lineState.stay)
machine:addTransition(lineState.stay, "timeout", lineState.move)

machine:stateTransition("timeout")
machine:stateTransition("timeout")
machine:stateTransition("timeout")

end, svrFunc.exception)
