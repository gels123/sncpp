-------fixecs.lua
-------
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")
local ecs = require "ecs"

xpcall(function()
	gLog.i("=====fixecs begin")
	print("=====fixecs begin")

	local N = 10000

	local w = ecs.world()
	gLog.i("memory:", w:memory())

	assert(w:register {
		name = "vector",
		"x:float",
		"y:float",
	}, 1)

	assert(w:register {
		name = "mark"
	}, 2)

	assert(w:register {
		name = "id",
		type = "int"
	}, 3)

	assert(w:register {
		name = "object",
		type = "lua",
	}, 4)

	local t = {}
	for i = 1, N do
		w:new {
			vector = {
				x = 1,
				y = 2,
			}
		}
		t[i] = { x = 1, y = 2 }
	end

	w:update()

	local function swap_c()
		for v in w:select "vector:update" do
			v.vector.x, v.vector.y = v.vector.y, v.vector.x
		end
	end

	local function swap_lua()
		for _, v in ipairs(t) do
			v.x, v.y = v.y, v.x
		end
	end

	local function timing(f)
		local c = os.clock()
		for i = 1, 1000 do
			f()
		end
		return os.clock() - c
	end

	gLog.i("memory:", w:memory())

	gLog.i("CSWAP", timing(swap_c))
	gLog.i("LUASWAP", timing(swap_lua))


	w:new {
		vector = {
			x = 3,
			y = 4,
		},
		id = 100,
	}
	table.insert(t, { x = 3, y = 4 })

	w:new {
		vector = {
			x = 5,
			y = 6,
		},
		mark = true,
	}
	table.insert(t, { x = 5, y = 6 })

	w:update()

	w:register {
		name = "singleton",
		type = "lua"
	}

	local context = w:context {
		"vector",
		"mark",
		"id",
		"singleton",
		"object",
	}

	w:new { singleton = "Hello World" }

	w:update()

	local test = require "ecs.ctest"

	local function csum()
		return test.sum(context)
	end
	gLog.i("csum = ", csum())

	local function luasum()
		local s = 0
		for v in w:select "vector:in" do
			s = s + v.vector.x + v.vector.y
		end
		return s
	end
	gLog.i("luasum = ", luasum())

	local function luanativesum()
		local s = 0
		for _, v in ipairs(t) do
			s = s + v.x + v.y
		end
		return s
	end
	gLog.i("lnative sum = ", luanativesum())

	gLog.i("CSUM", timing(csum))
	gLog.i("LUASUM", timing(luasum))
	gLog.i("LNATIVESUM", timing(luanativesum))



	--local f = function(x)
	--	for i=1,1000,1 do
	--		x = x * -1
	--	end
	--	return x
	--end
	--do
	--	local w = ecs.world()
	--
	--	assert(w:register {
	--		name = "vector",
	--		"x:float",
	--		"y:float",
	--	}, 1)
	--
	--	assert(w:register {
	--		name = "mark",
	--		type = "lua",
	--	}, 2)
	--
	--	-- Create a new entity with components vector and name.
	--	local n = 10000
	--	for i=1,n,1 do
	--		w:new {
	--			vector = { x=1.0*i, y=2.0*i },
	--			mark = "point",
	--		}
	--	end
	--	local time1 = skynet.time()
	--	for j=1,10,1 do
	--		local f = f
	--		for v in w:select "vector:in" do
	--			v.vector.x = f(v.vector.x)
	--			v.vector.y = f(v.vector.y)
	--		end
	--	end
	--	local time2 = skynet.time()
	--	gLog.i("fixecs use ecs time cost=", time2-time1) --cost= 13.730000019073 14.94000005722
	--end
	--
	--
	--do
	--	local n = 10000
	--	local tab = {}
	--	for i=1,n,1 do
	--		table.insert(tab, { x=1.0*i, y=2.0*i })
	--	end
	--	local time1 = skynet.time()
	--	for j=1,10,1 do
	--		local f = f
	--		for k,v in pairs(tab) do
	--			v.x = f(v.x)
	--			v.y = f(v.y)
	--		end
	--	end
	--	local time2 = skynet.time()
	--	gLog.i("fixecs use lua time cost=", time2-time1) --cost=
	--end

	gLog.i("=====fixecs end")
	print("=====fixecs end")
end,svrFunc.exception)