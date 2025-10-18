--[[ judy 编译
	@echo "\n\n\n========== make judy start =========="
	cd ./game/lib/lua-judy/judy;./configure
	cd ./game/lib/lua-judy/judy;make clean
	cd ./game/lib/lua-judy/judy;./configure && make && make check
	cd ./game/lib/lua-judy/judy/src;./sh_build
	cd ./game/lib/lua-judy;make linux
	cd ..
	@echo "========== make judy end =========="

	@echo "\n\n\n========== make lua-judy start =========="
	cd ./game/lib/lua-judy/;make linux
	cd ..
	@echo "========== make lua-judy end =========="
]]
local judycore = require "judy.core"
local judy = require "judy"
local skynet = require "skynet"


local myjudytest = nil
local myrettest = nil

myjudytest,myrettest = judycore.JSLI(myjudytest,"a2",10)
print("myjudytest = ",myjudytest, " ret=", myrettest )
print(" a2 == ",judycore.value(myrettest,judycore.NUMBER))
myjudytest,myrettest = judycore.JSLI(myjudytest,"a3",20)
print("2 myjudytest = ",myjudytest, " ret=", myrettest )
print(" a3 == ",judycore.value(myrettest,judycore.NUMBER))
myjudytest,myrettest = judycore.JSLI(myjudytest,"a4",30)
print("3 myjudytest = ",myjudytest, " ret=", myrettest )
print(" a4 == ",judycore.value(myrettest,judycore.NUMBER))

local testgot = judycore.JSLG(myjudytest,"a3")
print(" got a3 == ",judycore.value(testgot,judycore.NUMBER))
testgot = judycore.JSLG(myjudytest,"a5")
print(" got a2 == ",judycore.value(testgot,judycore.NUMBER))

print(" judy 1 = ",judycore.NUMBER)
print(" judy 2 = ",judycore.STRING)
print(" judy 3 = ",judycore.ARRAY)

local innerjudytest = nil
local innerjudyret = nil
innerjudytest,innerjudyret = judycore.JSLI(innerjudytest,"b2",10)
innerjudytest,innerjudyret = judycore.JSLI(innerjudytest,"b3",myjudytest)

print("direct a2= ",judycore.JSLG(innerjudytest,"b2",judycore.NUMBER))

local myjudy = nil
myjudy,_ = judycore.JSLI(myjudy,"a3",120)
myjudy,_ = judycore.JSLI(myjudy,"a4",130)
myjudy,_ = judycore.JSLI(myjudy,"a5",140)
myjudy,_ = judycore.JSLI(myjudy,"a6",150)
myjudy,_ = judycore.JSLI(myjudy,"a7","hello world")

print(" a5= ",judycore.JSLG(myjudy,"a5",judycore.NUMBER))
print(" a7= ",judycore.JSLG(myjudy,"a7",judycore.STRING))

-- judy.release(innerjudytest)


local judysl = judy.JudySL(judy.JUDYSL)
for i=1,10 do
	judysl:JSLI(tostring(i),i*100)
end
print("judysl data[2]=",judysl:JSLG("2",judy.NUMBER))	

local judyl = judy.JudyL(judy.JUDYL,false)
for i=1,2 do
	judyl:JLI((i),"jli-"..tostring(i))
end
print("======judyl data[2]=",judyl:JLG(2,judy.STRING))	
judyl:LForeach(function ( index,dd )
	if true then
		print("judyl foreach dd = ",index,dd)
	end
end,judycore.STRING)
print("judy JLMU======= ",judyl:JLMU())

-- for i=1,100 do
-- 	collectgarbage("collect")
-- end

local function test_mem(  )
	local loopcount = 5
	local tab = {}
	local memcount1 = collectgarbage("count")
	for i=1,loopcount do
		tab[tostring(i)] = i
	end
	local memcount2 = collectgarbage("count")
	print("mem delta = ",memcount2-memcount1)

	local judyarray = judy.JudySL(judy.JUDYSL)
	local memcount3 = collectgarbage("count")
	for i=1,loopcount do
		judyarray:JSLI(tostring(i),i)
	end
	local memcount4 = collectgarbage("count")
	print("mem delta2 = ",memcount4-memcount3)

	local t1 = os.time()
	for i=1,loopcount do			
		local d1 = tab[tostring(i)]
	end
	local t2 = os.time()
	print("time delta = ",t2-t1)

	local t3 = os.time()
	for i=1,loopcount do			
		local d1 = judyarray:JSLG(tostring(i),judy.NUMBER)
		-- print("d1=====",d1)
	end

	print("object before == ",judyl:cobject())
	judyarray:JSLI(tostring(11),judyl:cobject())
	local judylobject = judyarray:JSLG(tostring(11),judy.ARRAY)
	print("object after = ",judylobject)
	local constructJudyl = judy.JudyL(judy.JUDYL,false,judylobject)
	constructJudyl:LForeach(function ( index,dd )
		if true  then
			print("=====>inner judyl foreach dd = ",index,dd,judy.value(dd,judy.STRING))
		end
		-- judy.freestring(dd)
	end)
	-- constructJudyl = nil

	-- judyarray:SLForeach(function ( dd,key )
	-- 	print("dd = ",dd,key)
	-- end,judy.NUMBER)
	-- local dd,key = judyarray:JSLF("",judy.NUMBER)
	-- print("dd = ",dd,key)
	-- while dd do
	-- 	dd,key = judyarray:JSLN(key,judy.NUMBER)
	-- 	print("WHILE dd = ",dd,key)
	-- 	skynet.sleep(100)
	-- end

	local t4 = os.time()
	print("time delta2 = ",t4-t3)

	print("data[1234]=",tab["1234"],judyarray:JSLG("1234",judy.NUMBER))
	-- judyarray = nil
	for i=1,10 do
		collectgarbage("collect")
	end
end
skynet.fork(test_mem)