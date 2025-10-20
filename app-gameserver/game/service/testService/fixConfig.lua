--[[
  launcher方式热更配置例子
]]--
local logServiceName = ...

local sharedata = require "sharedataLib"
local skynet = require "skynet"

require "quickframework.init"
require "configInclude"
require "svrFunc"
include "constDefInit"

local ACTIVITY_BATTLE = {
	[1] = {suit=1, status=4, day=1, activityID = {}, rid = {}, },
	[2] = {suit=1, status=4, day=2, activityID = {}, rid = {}, },
	[3] = {suit=1, status=4, day=3, activityID = {}, rid = {}, },
	[4] = {suit=1, status=5, day=1, activityID = {}, rid= {9724, 26, }, },
	[5] = {suit=1, status=5, day=2, activityID = {}, rid = {}, },
	[6] = {suit=1, status=5, day=3, activityID = {}, rid = {}, },
	[7] = {suit=1, status=5, day=4, activityID = {}, rid= {10215, 1, 10216, 1, }, },
	[8] = {suit=1, status=5, day=5, activityID= {9001225, 7, }, rid= {10215, 1, 10216, 1, 10297, 6, 10298, 6, }, },
	[9] = {suit=1, status=5, day=6, activityID = {}, rid = {}, },
	[10] = {suit=1, status=5, day=7, activityID = {}, rid = {}, },
	[11] = {suit=1, status=5, day=8, activityID = {}, rid = {}, },
	[12] = {suit=1, status=5, day=9, activityID = {}, rid = {}, },
	[13] = {suit=1, status=5, day=10, activityID = {}, rid = {}, },
	[14] = {suit=1, status=5, day=11, activityID = {}, rid= {10215, 1, 10216, 1, }, },
	[15] = {suit=1, status=5, day=12, activityID= {9001225, 7, }, rid= {10215, 1, 10216, 1, }, },
	[16] = {suit=1, status=5, day=13, activityID = {}, rid = {}, },
	[17] = {suit=1, status=5, day=14, activityID = {}, rid = {}, },
	[18] = {suit=1, status=5, day=15, activityID = {}, rid = {}, },
	[19] = {suit=1, status=5, day=16, activityID = {}, rid = {}, },
	[20] = {suit=1, status=5, day=17, activityID = {}, rid = {}, },
	[21] = {suit=1, status=5, day=18, activityID = {}, rid= {10215, 1, 10216, 1, }, },
	[22] = {suit=1, status=5, day=19, activityID= {9001225, 7, }, rid= {10215, 1, 10216, 1, 10297, 6, 10298, 6, }, },
	[23] = {suit=1, status=5, day=20, activityID = {}, rid = {}, },
	[24] = {suit=1, status=5, day=21, activityID = {}, rid = {}, },
	[25] = {suit=1, status=5, day=22, activityID = {}, rid = {}, },
	[26] = {suit=1, status=5, day=23, activityID = {}, rid = {}, },
	[27] = {suit=1, status=5, day=24, activityID = {}, rid = {}, },
	[28] = {suit=1, status=5, day=25, activityID = {}, rid= {10215, 1, 10216, 1, }, },
	[29] = {suit=1, status=6, day=26, activityID = {}, rid= {10215, 1, 10216, 1, }, },
	[30] = {suit=2, status=3, day=7101, activityID = {}, rid= {10297, 5, 10298, 5, }, },
	[31] = {suit=2, status=3, day=7106, activityID = {}, rid= {10211, 3, 10212, 3, }, },
	[32] = {suit=3, status=2, day=0, activityID = {}, rid= {10213, 3, 10214, 3, 9525, 1, 9526, 1, }, },
	[33] = {suit=4, status=2, day=0, activityID = {}, rid= {10209, 14, 10210, 14, }, },
}
--大型活动关联的礼包自动上架配置
local function localDataConfigLogic_getLargeWarRechargePackage()
  local ret = {}
  local data = ACTIVITY_BATTLE
  for k,v in pairs(data) do
    v.activityID = svrFunc.tableFormat(v.activityID, {"id", "day"})
    v.rid = svrFunc.tableFormat(v.rid, {"rid", "day"})
    if not ret[v.suit] then
      ret[v.suit] = {}
    end
    if not ret[v.suit][v.status] then
      ret[v.suit][v.status] = {}
    end
    ret[v.suit][v.status][v.day] = v
  end
  -- gLog.dump(ret, "localDataConfigLogic.getLargeWarRechargePackage ret=", 10)
  return ret
end

local function setShareData(configkeys, svrNameList)
  gLog.dump(svrNameList,"fix fixLargeActivity0715 setShareData1",10)
  local retList = skynet.call(".launcher", "lua", "LIST")
  for strAddress,strSvrName in pairs(retList) do
    local address = string.format("%d","0x"..string.sub(strAddress,2))
    local arrName = string.split(strSvrName, " ")
    local svrName = arrName[2]
    if svrNameList[svrName] then 
      gLog.i("fix fixLargeActivity0715 setShareData2",svrName,address)
      local injectstr = string.format("gLog.i(\"fix new cfg\") \n local sharedata = require \"sharedataLib\" \n local keys = string.split(\"%s\",\",\") \n for _, key in pairs(keys) do \n if sharedata.isQueryed( key ) then \n sharedata.update( key ) \n end \n end\n", table.concat(configkeys,","))
      gLog.i("str ===",injectstr)
      xpcall(function()
        skynet.send(address, "debug", "RUN", injectstr)
      end, svrFunc.error)
    end
  end
end

skynet.start(function ()
   
  gLog.i("fix fixLargeActivity0715 begin")
  local svrNameList = {
    ["rechargeService"] = true,
  }

  local configkeys = {
    "LOCAL_LARGE_WAR_RECHARGE_PACKAGE",
  }

  skynet.fork(function ()

  	local cfg = localDataConfigLogic_getLargeWarRechargePackage()
    sharedata.new("LOCAL_LARGE_WAR_RECHARGE_PACKAGE", cfg)

    setShareData(configkeys, svrNameList)
    gLog.i("fix fixLargeActivity0715 success")
    skynet.exit()
  end)
  
end)