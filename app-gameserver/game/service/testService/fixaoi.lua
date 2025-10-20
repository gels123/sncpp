-------fixaoi.lua
-------
local skynet = require ("skynet")
local cluster = require ("cluster")

xpcall(function()
    gLog.i("=====fixaoi begin")
    print("=====fixaoi begin")

    --local aoi = require("aoi").new()
    --aoi:add(0,"w",{x=40,y=0},{x=0,y=1})
    --aoi:add(1,"wm",{x=42,y=100},{x=0,y=-1})
    ----aoi:add(2,"w",{x=0,y=40},{x=1,y=0})
    ----aoi:add(3,"wm",{x=100,y=45},{x=-1,y=0})
    --aoi:setRadis(20)
    --local function update_obj(id)
    --    local obj = aoi:get(id)
    --    if obj then
    --        for i=1,3 do
    --            obj.pos[i] = obj.pos[i] + obj.v[i]
    --            --if obj.pos[i] < 0 then
    --            --    obj.pos[i] = obj.pos[i] + 100.0
    --            --elseif obj.pos[i] > 100 then
    --            --    obj.pos[i] = obj.pos[i] - 100.0
    --            --end
    --        end
    --        aoi:update(id,obj.pos[1],obj.pos[2],obj.pos[3])
    --    end
    --end
    --for i=0, 9999 do
    --    if i < 50 then
    --        for j=0,1 do
    --            update_obj(j)
    --        end
    --    elseif i == 50 then
    --        aoi:delete(3)
    --    else
    --        for j=0,1 do
    --            update_obj(j)
    --        end
    --    end
    --    local ret = aoi:message()
    --    if ret and next(ret) then
    --        gLog.dump(ret,"ret = second=" .. i,10)
    --        local len = #ret
    --        for idx=1,len, 2 do
    --            local watcher = ret[idx]
    --            local marker  = ret[idx+1]
    --            local wobj = aoi:get(watcher)
    --            local mobj = aoi:get(marker)
    --            gLog.d(string.format("watcher=%d (%f,%f)==> marker%d (%f,%f)",watcher,wobj.pos[1],wobj.pos[2],marker, mobj.pos[1],mobj.pos[2]))
    --        end
    --
    --    end
    --    -- gLog.dump(ret,"ret ==" .. i,10)
    --end


    local aoi = require("aoi").new(20)
    aoi:add(1,"m",{x=1,y=1}, {x=0,y=0})
    aoi:add(2,"m",{x=20,y=20}, {x=0,y=0})
    aoi:add(3,"wm",{x=0,y=0},{x=1,y=1})
    aoi:setRadis(20)
    local function update_obj(id, tick)
        local obj = aoi:get(id)
        if obj then
            for i=1,3 do
                obj.pos[i] = obj.pos[i] + obj.v[i]
            end
            aoi:update(id, obj.pos[1], obj.pos[2], obj.pos[3])
        end
    end

    local tick = 100
    local second = 0
    while(true) do
        second = second + 1
        --
        update_obj(3, tick)
        --
        local ret = aoi:message()
        gLog.dump(ret,"ret message second=" .. second,10)
        if ret and next(ret) then
            local len = #ret
            for idx=1,len, 2 do
                local watcher = ret[idx]
                local marker  = ret[idx+1]
                local wobj = aoi:get(watcher)
                local mobj = aoi:get(marker)
                gLog.d("ret message idx=", idx, "second=", second, "watcher=", watcher,wobj.pos[1],wobj.pos[2], "marker=", marker, mobj.pos[1],mobj.pos[2])
            end
        end
        skynet.sleep(tick)
    end

    gLog.i("=====fixaoi end")
    print("=====fixaoi end")
end,svrFunc.exception)