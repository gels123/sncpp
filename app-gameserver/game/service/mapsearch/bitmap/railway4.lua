--[[
    测试铁轨联通配置
]]
railway = {
    {id1 = 10000*3+2, id2 = 10000*7+7, distance = 9},
}

local idx = 0
function getRailway()
    idx = idx + 1
    if railway[idx] then
        return railway[idx].id1, railway[idx].id2, railway[idx].distance
    else
        return 0, 0, 0
    end
end

return railway
