lua-aoi
import from https://github.com/cloudwu/aoi
======

local aoi = require("aoi").new()
aoi:add(0,"w",{x=40,y=0},{x=0,y=1})
aoi:add(1,"wm",{x=42,y=100},{x=0,y=-1})
aoi:add(2,"w",{x=0,y=40},{x=1,y=0})
aoi:add(3,"wm",{x=100,y=45},{x=-1,y=0})
aoi:setRadis(20)
local function update_obj(ID)
    local OBJ = aoi:get(ID)
    if OBJ then
        for i=1,3 do
            OBJ.pos[i] = OBJ.pos[i] + OBJ.v[i]
            if OBJ.pos[i] < 0 then
                OBJ.pos[i] = OBJ.pos[i] + 100.0
            elseif OBJ.pos[i] > 100 then
                OBJ.pos[i] = OBJ.pos[i] - 100.0
            end
        end
        aoi:update(ID,OBJ.pos[1],OBJ.pos[2],OBJ.pos[3])
    end
end

for i=0, 99 do
    if i < 50 then
        for j=0,3 do
            update_obj(j)
        end
    elseif i == 50 then
        aoi:delete(3)
    else
        for j=0,3 do
            update_obj(j)
        end
    end
    local ret = aoi:message()
    if ret and next(ret) then
        gLog.dump(ret,"ret ==" .. i,10)
        local len = #ret
        for idx=1,len, 2 do
            local watcher = ret[idx]
            local marker  = ret[idx+1]
            local wobj = aoi:get(watcher)
            local mobj = aoi:get(marker)
            print(string.format("%d (%f,%f)==> %d (%f,%f)",watcher,wobj.pos[1],wobj.pos[2],marker, mobj.pos[1],mobj.pos[2]))
        end
        
    end
    -- gLog.dump(ret,"ret ==" .. i,10)
end
gLog.i("want to exit")
skynet.sleep(200)
os.exit()




