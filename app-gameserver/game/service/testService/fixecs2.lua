-------fixecs2.lua
-------
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")
local ecs = require "ecs"

xpcall(function()
	gLog.i("=====fixecs2 begin")
	print("=====fixecs2 begin")

	--local ECS = require("ECS")
	--local World, System, Query, Component = ECS.World, ECS.System, ECS.Query, ECS.Component
	--
	--local Health = Component(100)
	--local Position = Component({ x = 0, y = 0})
	--
	--local isInAcid = Query.Filter(function()
	--	return true  -- it's wet season
	--end)
	--
	--local InAcidSystem = System("process", Query.All( Health, Position, isInAcid() ))
	--
	--function InAcidSystem:Update()
	--	gLog.d("====InAcidSystem:Update====")
	--	for i, entity in self:Result():Iterator() do
	--		local health = entity[Health]
	--		gLog.dump(health, "=====xxxxxxxxxxxx health=")
	--		health.value = health.value - 0.01
	--	end
	--end
	--
	--local world = World({ InAcidSystem })
	--
	--world:Entity(Position({ x = 5.0 }), Health())
	--world:Update("process", os.clock())


	local tiny = require("tiny")

	local talkingSystem = tiny.processingSystem()
	talkingSystem.filter = tiny.requireAll("name", "mass", "phrase")
	function talkingSystem:process(e, dt)
		e.mass = e.mass + dt * 3
		print(("%s who weighs %d pounds, says %q."):format(e.name, e.mass, e.phrase))
	end

	local joe = {
		name = "Joe",
		phrase = "I'm a plumber.",
		mass = 150,
		hairColor = "brown"
	}

	local world = tiny.world(talkingSystem, joe)

	for i = 1, 20 do
		world:update(1)
	end

	gLog.i("=====fixecs2 end")
	print("=====fixecs2 end")
end,svrFunc.exception)