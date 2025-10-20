-------fixtablemonitor.lua
-------
local skynet = require ("skynet")
local json = require ("json")
local redisLib = require ("redisLib")
local cluster = require ("cluster")
local json = require("json")

xpcall(function()
	gLog.i("=====fixtablemonitor begin")
	print("=====fixtablemonitor begin")

	local tableMonitor = require("tableMonitor")
	tableMonitor.init()

	local function test()
		local tab = {
			[1] = 1,
			[2] = 2,
			[3] = 3,

			num = 100,
			str = "s1",

			t1 = {
				[1] = 11,
				[2] = 12,
				[3] = 13,

				num = 200,
				str = "s2",

				t3 = {
					rate = 0.01
				},
			},
		}
		setmetatable(tab, {
			__index = function(_, k)
				if "meta" == k then
					return "meta11"
				end
			end
		})
		gLog.dump(tab, "fixtablemonitor step1=")

		local function mark(path, k, v)
			gLog.i(string.format("mark %s.%s %s", path, k, v))
			-- 这里可标脏，在写库操作时清除
			-- 在指令操作结束时检查下是否还有标脏的模块
		end

		tab = tableMonitor.encode(tab, mark)
		gLog.dump(tab, "fixtablemonitor step2=")
		for k,v in ipairs(tab) do
			gLog.i(tab, "fixtablemonitor step3 #t=", #tab, "k=", k, "v=", v)
		end


		tab[1] = 1.1
		tab.num = 200.1
		tab.str = "s1.1"
		tab.str2 = "s1.2"
		tab.t1[1] = 11.1
		tab.t1.num = 200.1
		tab.t1.str = "s2.1"
		tab.t1.str2 = "s2.2"
		tab.t1.t3.rate = 1.001
		local tmp = {}
		tab.t1.t3 = tmp
		tab.t1.t3.rate = 2.001
		tmp.rate = 3.001
		gLog.dump(tab, "fixtablemonitor step4=")

		gLog.i("fixtablemonitor step5=", json.encode(tab))

		gLog.i("fixtablemonitor step6=", json.encode(tableMonitor.getReal(tab)))

		gLog.i("fixtablemonitor step7=", tab.meta)

		tab = tableMonitor.decode(tab)
		tab[1] = 1.0001
		tab.t1[1] = 11.001
		gLog.dump(tab, "fixtablemonitor step8=")
	end

	test()

	gLog.i("=====fixtablemonitor end")
	print("=====fixtablemonitor end")
end,svrFunc.exception)