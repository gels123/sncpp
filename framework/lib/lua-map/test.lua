local mmomap = require("mmomap")
gLog.i("=====sdfadf====mmomap=", mmoArray[0], mmoArray[1])

local map = MmoMap:new(5, 6)
gLog.i("xxxxxxxxx1====", map:GetSize())
local info = map:GetInfo()
gLog.i("xxxxxxxxx2====", info.x, info.y, info.str, info)