if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local socket = require "client.socket"

-- 通信协议
local proto = require "protoTest"
local sproto = require "sproto"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local fd = assert(socket.connect("127.0.0.1", 8888))

local session = 0
local function send_request(name, args)
    session = session + 1
    local str = request(name, args, session)

    -- 解包测试
    -- local host2 = sproto.new(proto.c2s):host "package"
    -- local type,str2 = host2:dispatch(str)
    -- print(type)
    -- print(str2)

    socket.send(fd, str)

    print("Request:", session)
end

send_request("handshake")
send_request("say", { name = "soul", msg = "hello world" })

while true do
    -- 接收服务器返回消息
    local str = socket.recv(fd)

    -- print(str)
    if str~=nil and str~="" then
            print("server says: "..str)
            -- socket.close(fd)
            -- break;
    end

    -- 读取用户输入消息
    local readstr = socket.readstdin()

    if readstr then
        if readstr == "quit" then
            send_request("quit")
            -- socket.close(fd)
            -- break;
        else
            -- 把用户输入消息发送给服务器
            send_request("say", { name = "soul", msg = readstr })
        end
    else
        socket.usleep(100)
    end

end