local mapSearch = require "mapSearch"
local mapFinder = class("mapFinder")

function mapFinder:ctor()
	self.super.ctor(self)
	
	self.obj = mapSearch()
end

function mapFinder:testFun(a, b)
	return self.obj:testFun(a, b)
end

return M

