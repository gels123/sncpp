
local chashclass = require("conhash")
dump("class ==",chashclass,10)
local chash = chashclass()
chash:addnode("192.168.100.1;10091", 50);
chash:addnode("192.168.100.2;10091", 50);
chash:addnode("192.168.100.3;10091", 50);
chash:addnode("192.168.100.4;10091", 50);

print("virtual nodes number == ",chash:count())
for i=1,30 do
    local rediskey = "Redis-key.km0" .. i
    if i < 10 then
        rediskey = "Redis-key.km00" .. i
    end
    -- [Redis-key.km001] is in node: [192.168.100.1;10091]
    local nodestr = chash:lookup( rediskey )
    print("[",rediskey,"] is in node: [", nodestr,"]")
    if i == 15 then
        chash:deletenode("192.168.100.4;10091")
    elseif i == 20 then
        chash:addnode("192.168.100.4;10091",50)
    end
end
local rediskey = "Redis-key.km015"
local nodestr = chash:lookup( rediskey )
print("[",rediskey,"] is in node: [", nodestr,"]")
skynet.sleep(100)