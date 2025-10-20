local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local socket = require "skynet.socket"

local function send_package(fd, pack)
    -- 协议与客户端对应(两字节长度包头+内容)
    --pack = string.pack(">s2", pack)
    socket.write(fd, pack)
end

local function accept(id)
    skynet.fork(function()
        -- 每当 accept 函数获得一个新的 socket id 后，并不会立即收到这个 socket 上的数据。这是因为，我们有时会希望把这个 socket 的操作权转让给别的服务去处理。
        -- 任何一个服务只有在调用 socket.start(id) 之后，才可以收到这个 socket 上的数据。
        socket.start(id)
        while true do
            local str = socket.read(id)
            if str then
                --str = string.unpack(">s2", str)
                print("accept message id=", id, "str=", str)
                send_package(id, str.."OK")
            else
                print("accept return")
                socket.close(id)
                return
            end
        end
    end)
end

skynet.start(function()
    local sid = socket.listen("0.0.0.0", 1234)
    print("listen socket :", "127.0.0.1", 1234)

    socket.start(sid , function(id, addr)
        -- 接收到客户端连接或发送消息()
        print("connect from " .. addr .. " " .. id)

        -- 处理接收到的消息
        accept(id)
    end)
    -- 可以为自己注册一个别名。（别名必须在 32 个字符以内）
    skynet.register ".fix_tcp_socket"
end)