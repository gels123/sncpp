local core = require "judy.core"

local judy = {
	--see lua-judy.c define
	--array type
	JUDYL=core.JUDYL,
	JUDYSL=core.JUDYSL,
	JUDYHS=core.JUDYHS,
	--data type
	NUMBER=core.NUMBER,
	STRING=core.STRING,
	ARRAY=core.ARRAY,
}

--[[get PValue
]]
function judy.value(cobj,type)
	print("type === ",type)
	local ret = core.value(cobj,type)
	return ret
end

--[[freestring
]]
function judy.freestring(cobj)
	local ret = core.freestring(cobj)
	return ret
end


---------------------------------------------------------------------JudySL BEGIN---------------------------------------------------------------------
local judyl = {}

local judylmeta = {
	__index = judyl,
	__gc = function(self)
		print("call JudyL gc ->",self.__autorelease)
		if self.__autorelease then
			core.JLFA(self.__cobj)
			self.__cobj = nil
			print("call JudyL gc -> deleted")
		else
			self.__cobj = nil
			print("call JudyL gc")
		end
	end,
}

function judy.JudyL(type,autorelease,cobject)
	local cobj = cobject or ( core.Judy() )
	if nil == autorelease then autorelease = true end
	local self = {
		__cobj = cobj,
		__type = type,
		__autorelease = autorelease,
	}
	return setmetatable(self, judylmeta)
end

--[[return c object
]]
function judyl:cobject()
	return self.__cobj
end

--[[release c object directly
]]
function judyl:release()
	if self.__cobj then
		core.JLFA(self.__cobj)
		self.__cobj = nil
		self.__autorelease = false --set to false to disable autorelease when auto GC function take effect
 		print("call JudyL gc -> deleted directly")
	end
end

--[[Insert an Index and Value into the JudyL array PJLArray. If the Index is successfully inserted, the Value is initialized to 0. 
If the Index was already present, the Value is not modified.Return PValue pointing to Value
]]
function judyl:JLI(index,value)
	local ret = nil
	self.__cobj,ret = core.JLI(self.__cobj,index,value)
	return ret
end

--[[Get the pointer PValue associated with Index in the PJLArray Judy array.
]]
function judyl:JLG(index,type)
	local ret = core.JLG(self.__cobj,index,type)
	return ret
end

--[[Delete the Index/Value pair from the JudyL array.
]]
function judyl:JLD(index)
	local ret = nil
	self.__cobj,ret = core.JLD(self.__cobj,index)
	return ret
end

--[[Count the number of indexes present in the JudyL array PJLArray between Index1 and Index2 (inclusive).
Return Rc_word set to the count. A return value of 0 can be valid as a count.
]]
function judyl:JLC(begin,last)
	local ret = nil
	self.__cobj,ret = core.JLC(self.__cobj,begin,last)
	return ret
end

--[[Locate the Nth index that is present in the JudyL array PJLArray (Nth = 1 returns the first index present).
Return PValue pointing to its Value and Index set to the Nth index if found, otherwise return PValue set to NULL (the value of Index is undefined).
]]
function judyl:JLBC(index,nth,type)
	local ret = nil
	local retIndex = nil
	self.__cobj,ret,retIndex = core.JLBC(self.__cobj,index,nth,type)
	return ret,retIndex
end

--[[Return Rc_word set to the number of bytes of memory malloc()'ed by PJLArray. 
This is a very fast routine, and may be used before and after a JLI() or JLD() call with little performance impact.
]]
function judyl:JLMU()
	local ret = core.JLMU(self.__cobj)
	return ret
end

--[[Search (inclusive) for the first index present that is equal to or greater than the passed Index. (Start with Index = 0 to find the first index in the array.) 
JLF() is typically used to begin a sorted-order scan of the indexes present in a JudyL array.
]]
function judyl:JLF(index,type)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLF(self.__cobj,index,type)
	return ret,retIndex
end

--[[Search (exclusive) for the next index present that is greater than the passed Index. 
JLN() is typically used to continue a sorted-order scan of the indexes present in a JudyL array, or to locate a "neighbor" of a given index.
]]
function judyl:JLN(index,type)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLN(self.__cobj,index,type)
	return ret,retIndex
end

--[[Search (inclusive) for the last index present that is equal to or less than the passed Index. (Start with Index = -1, that is, all ones, to find the last index in the array.) 
JLL() is typically used to begin a reverse-sorted-order scan of the indexes present in a JudyL array.
]]
function judyl:JLL(index,type)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLL(self.__cobj,index,type)
	return ret,retIndex
end

--[[Search (exclusive) for the previous index present that is less than the passed Index. 
JLP() is typically used to continue a reverse-sorted-order scan of the indexes present in a JudyL array, or to locate a "neighbor" of a given index.
]]
function judyl:JLP(index,type)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLP(self.__cobj,index,type)
	return ret,retIndex
end

--[[Search (inclusive) for the first index absent that is equal to or greater than the passed Index. (Start with Index = 0 to find the first index absent in the array.)
]]
function judyl:JLFE(index)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLFE(self.__cobj,index)
	return ret,retIndex
end

--[[Search (exclusive) for the next index absent that is greater than the passed Index.
]]
function judyl:JLNE(index)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLNE(self.__cobj,index)
	return ret,retIndex
end

--[[Search (inclusive) for the last index absent that is equal to or less than the passed Index. (Start with Index = -1, that is, all ones, to find the last index absent in the array.)
]]
function judyl:JLLE(index)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLLE(self.__cobj,index)
	return ret,retIndex
end

--[[Search (exclusive) for the previous index absent that is less than the passed Index.
]]
function judyl:JLPE(index)
	local ret,retIndex
	self.__cobj,ret,retIndex = core.JLPE(self.__cobj,index)
	return ret,retIndex
end

--[[遍历
useage:
local judyl = judy.JudyL(judycore.JUDYL)
for i=1,10 do
	judyl:JLI((i),i*5)
end
print("======judyl data[2]=",judyl:JLG(2,judycore.NUMBER))	
judyl:LForeach(function ( index,dd )
	print("judyl foreach dd = ",dd,index)
end,judycore.NUMBER)
]]
function judyl:LForeach(func,type)
	local data,index = self:JLF(0,type)
	if nil ~= data then
		func(index,data)
		while data do
			data,index = self:JLN(index,type)
			if nil ~= data then
				func(index,data)
			end
		end
	end
end

---------------------------------------------------------------------JudyL END---------------------------------------------------------------------


---------------------------------------------------------------------JudySL BEGIN---------------------------------------------------------------------
local judysl = {}

local judyslmeta = {
	__index = judysl,
	__gc = function(self)
		print("call JudySL gc ->",self.__autorelease)
		if self.__autorelease then
			core.JSLFA(self.__cobj)
			self.__cobj = nil
			print("call JudySL gc -> deleted")
		else
			self.__cobj = nil
			print("call JudySL gc")
		end
	end,
}

function judy.JudySL(type,autorelease,cobject)
	local cobj = cobject or ( core.Judy() )
	if nil == autorelease then autorelease = true end
	local self = {
		__cobj = cobj,
		__type = type,
		__autorelease = autorelease,
	}
	return setmetatable(self, judyslmeta)
end

--[[return c object
]]
function judysl:cobject()
	return self.__cobj
end

--[[release c object directly
]]
function judysl:release()
	if self.__cobj then
		core.JSLFA(self.__cobj)
		self.__cobj = nil
		self.__autorelease = false --set to false to disable autorelease when auto GC function take effect
 		print("call JudySL gc -> deleted directly")
	end
end

--[[Insert an Index string and Value in the JudySL array PJSLArray. If the Index is successfully inserted, the Value is initialized to 0. 
If the Index was already present, the Value is not modified.Return PValue pointing to Index's Value
]]
function judysl:JSLI(key,value)
	local ret = nil
	self.__cobj,ret = core.JSLI(self.__cobj,key,value)
	return ret
end

--[[Get the pointer to Index's Value.
]]
function judysl:JSLG(key,type)
	local ret = core.JSLG(self.__cobj,key,type)
	return ret
end

--[[Delete the specified Index/Value pair (array element) from the JudySL array.
]]
function judysl:JSLD(key)
	local ret = nil
	self.__cobj,ret = core.JSLD(self.__cobj,key)
	return ret
end

--[[Search (inclusive) for the first index present that is equal to or greater than the passed Index string.
 (Start with a null string to find the first index in the array.) 
JSLF() is typically used to begin a sorted-order scan of the valid indexes in a JudySL array.
]]
function judysl:JSLF(key,type)
	local ret,retkey
	self.__cobj,ret,retkey = core.JSLF(self.__cobj,key,type)
	return ret,retkey
end

--[[Search (exclusive) for the next index present that is greater than the passed Index string. 
JSLN() is typically used to continue a sorted-order scan of the valid indexes in a JudySL array, or to locate a "neighbor" of a given index.
]]
function judysl:JSLN(key,type)
	local ret,retkey
	self.__cobj,ret,retkey = core.JSLN(self.__cobj,key,type)
	return ret,retkey
end

--[[Search (inclusive) for the last index present that is equal to or less than the passed Index string. 
(Start with a maximum-valued string to look up the last index in the array, such as a max-length string of 0xff bytes.) 
JSLL() is typically used to begin a reverse-sorted-order scan of the valid indexes in a JudySL array.
]]
function judysl:JSLL(key,type)
	local ret,retkey
	self.__cobj,ret,retkey = core.JSLL(self.__cobj,key,type)
	return ret,retkey
end

--[[Search (exclusive) for the previous index present that is less than the passed Index string.
JSLP() is typically used to continue a reverse-sorted-order scan of the valid indexes in a JudySL array,
or to locate a "neighbor" of a given index.
]]
function judysl:JSLP(key,type)
	local ret,retkey
	self.__cobj,ret,retkey = core.JSLP(self.__cobj,key,type)
	return ret,retkey
end

--[[wrapper foreach function
useage:
obj:JSForeach(function ( dd,key )
			print("dd = ",dd,key)
		end,judy.NUMBER)
]]
function judysl:SLForeach(func,type)
	local data,key = self:JSLF("",type)
	if nil ~= data then
		func(key,data)
		while data do
			data,key = self:JSLN(key,type)
			if nil ~= data then
				func(key,data)
			end
		end
	end
end
---------------------------------------------------------------------JudySL END ---------------------------------------------------------------------



---------------------------------------------------------------------JudyHS BEGIN---------------------------------------------------------------------

local judyhs = {}

local judyhsmeta = {
	__index = judyhs,
	__gc = function(self)
		print("call JudyHS gc ->",self.__autorelease)
		if self.__autorelease then
			core.JHSFA(self.__cobj)
			self.__cobj = nil
			print("call JudyHS gc -> deleted")
		else
			self.__cobj = nil
			print("call JudyHS gc")
		end
	end,
}

function judy.JudyHS(type,autorelease,cobject)
	local cobj = cobject or ( core.Judy() )
	if nil == autorelease then autorelease = true end
	local self = {
		__cobj = cobj,
		__type = type,
		__autorelease = autorelease,
	}
	return setmetatable(self, judyhsmeta)
end

--[[return c object
]]
function judyhs:cobject()
	return self.__cobj
end

--[[release c object directly
]]
function judyhs:release()
	if self.__cobj then
		core.JHSFA(self.__cobj)
		self.__cobj = nil
		self.__autorelease = false --set to false to disable autorelease when auto GC function take effect
 		print("call JudyHS gc -> deleted directly")
	end
end

--[[
]]
function judyhs:JHSI(key,value)
	local ret = nil
	self.__cobj,ret = core.JHSI(self.__cobj,key,value)
	return ret
end

--[[Get the pointer to Index's Value.
]]
function judyhs:JHSG(key,type)
	local ret = core.JHSG(self.__cobj,key,type)
	return ret
end

--[[
]]
function judyhs:JHSD(key)
	local ret = nil
	self.__cobj,ret = core.JHSD(self.__cobj,key)
	return ret
end
---------------------------------------------------------------------JudyHS END---------------------------------------------------------------------

return judy