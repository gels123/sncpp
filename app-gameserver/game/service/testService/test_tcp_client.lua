
package.cpath =
        "skynet/luaclib/?.so;" ..
        "skynet/cservice/?.so;" ..
        "game/lib/lua-timer/?.so;" ..
        "game/lib/lua-socket/src/?.so;" ..
        "game/lib/lua-lfs/?.so;" ..
        "game/lib/lua-bit32/?.so;" ..
        "game/lib/lua-json/?.so;"

package.path =
        "?.lua;" ..
        "skynet/lualib/?.lua;" ..
        "skynet/lualib/compat10/?.lua;" ..
        "game/lib/?.lua;" ..
        "game/lib/lua-timer/?.lua;" ..
        "game/lib/lua-socket/?.lua;" ..
        "game/lib/lua-json/?.lua;"

local json = require("json")
local socket = require "client.socket"
local fd = assert(socket.connect("127.0.0.1", 1234))

local sessionid = 0
local function send_request(str)
    sessionid = sessionid + 1

    str = json.encode({sessionid = sessionid, str = str,})
    --str = string.pack(">s2", str)
    socket.send(fd, str)

    print("send to server str=", str)
end

send_request("==first message==")

while true do
    -- 接收服务器返回消息
    local str = socket.recv(fd)

    -- print(str)
    if str~=nil then
        if str == "" then
            break
        else
            --str = string.unpack(">s2", str)
            print("receive from server str=", str)
        end
    end

    -- 读取用户输入消息
    local readstr = socket.readstdin()
    if readstr then
        if readstr == "quit" or readstr == "exit" then
            socket.close(fd)
            break;
        else
            -- 把用户输入消息发送给服务器
            send_request(readstr)
        end
    else
        socket.usleep(100)
    end
end