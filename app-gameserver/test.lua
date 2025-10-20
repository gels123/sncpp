
local function f2(...)
    print("-------hhhhhh1---------,", ...)
    local a1,a2,a3,a4 = coroutine.yield(999,...)
    print("-------hhhhhh2---------,", ..., "ret=", a1, a2, a3, a4)
    return 100, 200
end
local co = coroutine.create(f2)

local a,b,c,d = coroutine.resume(co, "aa", "bb")
print("================ret=", a, b, c, d)

local a,b,c,d = coroutine.resume(co)
print("================ret2=", a, b, c, d)

