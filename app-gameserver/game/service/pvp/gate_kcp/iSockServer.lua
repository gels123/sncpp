--[[
	sockect之udp+kcp/udp+kcp+fec封装
	测试记录: 2022.10.24 17:02, 美西服务器, upd平均延迟190ms, 网络状况较好, tcp延迟250-350, 网络状况较差
]]
local skynet = require("skynet")
local skynetcore = require "skynet.core"
local skynetqueue = require "skynet.queue"
local socketdriver = require "skynet.socketdriver"
local netpack = require "skynet.netpack"
local lkcp = require "lkcpsn"
local lutil = require "lutil"
local cmdCtrl = require "clientCmd"
local protoLib = require "protoLib"
local iSockServer = class("iSockServer")

-- socket模式
local eSocketMode = {
    eTcp = 1,       -- TCP
    eUdpKcp = 3,    -- UDP+KCP
    eUdpKcpFec = 4, -- UDP+KCP+FEC
}

-- 构造
function iSockServer:ctor()
    self.mode = nil     -- 模式
    self.port = nil     -- 端口
    self.sock = nil     -- sock

    self.connection = {} -- 连接
    self.connectNum = 0  -- 连接数
    self.connectMax = 5000 -- 最大连接数
    self.uidMap = {}    -- uid关联信息
    self.subid = 0      -- 连接id
    self.handshakeMap = {} -- uid握手关联信息
    self.handshakeFrom = {} -- from握手关联信息

    self.queue = nil    -- tcp消息队列
    self.handshakeFd = {} -- tcp握手关联信息
    self.nodelay = true -- 是否无延迟

    self.sq = skynetqueue()
end

-- 初始化
function iSockServer:init(mode, port)
    gLog.i("==iSockServer:init begin==", mode, port)
    -- 模式
    assert((mode == eSocketMode.eTcp or mode == eSocketMode.eUdpKcp or mode == eSocketMode.eUdpKcpFec), "iSockServer:init error, mode is not support "..mode)
    self.mode = mode or eSocketMode.eUdpKcp
    -- 端口
    self.port = port or 8765
    -- 注册协议
    if mode == eSocketMode.eTcp then
        -- 注册协议Tcp
        local MSG = {
            data = assert(self.dispatch_msg_tcp),
            more = assert(self.dispatch_queue_tcp),
            open = assert(self.open_tcp),
            close = assert(self.close_tcp),
            error = assert(self.close_tcp),
        }
        skynet.register_protocol({
            name = "socket",
            id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET = 6
            unpack = function (msg, sz)
                return netpack.filter(self.queue, msg, sz)
            end,
            dispatch = function (session, source, q, t, ...)
                self.queue = q
                if t and MSG[t] then
                    MSG[t](self, ...)
                end
            end
        })
        -- 开启监听
        if self.sock then
            socketdriver.close(self.sock)
            self.sock = nil
        end
        local listen = "0.0.0.0"
        gLog.i("iSockServer:init listen on=", listen, self.port)
        self.sock = socketdriver.listen(listen, self.port)
        assert(self.sock, "iSockServer:init error: create tcp socket")
        socketdriver.start(self.sock)
    else
        -- 注册协议UDP
        skynet.register_protocol({
            name = "socket",
            id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET = 6
            unpack = socketdriver.unpack,
            dispatch = function(_, _, t, id, sz, msg, from)
                if t == 6 then -- SKYNET_SOCKET_TYPE_UDP = 6
                    if id == self.sock then
                        self:dispatch_msg(from, msg, sz)
                    else
                        skynet.error("iSockServer socket drop udp package fd=" .. id)
                        socketdriver.drop(msg, sz)
                    end
                end
            end
        })
        -- 开启监听
        if self.sock then
            socketdriver.close(self.sock)
            self.sock = nil
        end
        local listen = "0.0.0.0"
        gLog.i("iSockServer:init listen on=", listen, port)
        self.sock = socketdriver.udp(listen, self.port)
        assert(self.sock, "iSockServer:init error: create udp socket")
    end
    gLog.i("iSockServer:init ok, mode=", self.mode, "port=", port, "sock=", self.sock)
    return true
end

-- 分发消息
function iSockServer:dispatch_msg(from, msg, sz)
    --gLog.d("iSockServer:dispatch udp mode=", self.mode, "from=", socketdriver.udp_address(from), "msg=", skynet.tostring(msg, sz), "sz=", sz)
    -- 获取数据
    local str_ = skynet.tostring(msg, sz)
    skynetcore.trash(msg, sz)
    -- 处理数据
    local subid, str = self:unpack_package(str_)
    --gLog.d("iSockServer:dispatch udp do enter from=", socketdriver.udp_address(from), "subid=", subid, "str=", str)
    if subid then
        if subid == 0 then
            -- 创建kcp, 用于握手
            local kcp = self:getKcp(from, 0, 0)
            -- 若收到udp包, 则作为下层协议输入到kcp
            local hrlen, hr = self.sq(function()
                kcp:lkcp_input(str, from)
                kcp:lkcp_update(self:getms())
                return kcp:lkcp_recv()
            end)
            gLog.d("iSockServer:dispatch udp do handshake, from=", socketdriver.udp_address(from), "subid=", subid, "hrlen=", hrlen, "hr=", hr)
            if hrlen > 0 then
                local arr = svrFunc.split(hr, "@")
                local uid, time = tonumber(arr[2]), tonumber(arr[3])
                if uid and uid > 0 and time and time > 0 and time > (self.handshakeMap[uid] and self.handshakeMap[uid].time or 0) then
                    -- 维护uid握手关联信息
                    if self.handshakeMap[uid] then
                        self.handshakeFrom[self.handshakeMap[uid].from] = nil
                        self.handshakeMap[uid] = nil
                    end
                    self.handshakeMap[uid] = {
                        uid = uid,
                        from = from,
                        subid = self.subid,
                        kcp = kcp,
                        ip = socketdriver.udp_address(from),
                        ms = 0,
                        time = time,
                    }
                    self.handshakeFrom[from] = self.handshakeMap[uid]
                    -- 回复握手包
                    self.subid = self.subid + 1
                    if self.subid >= 4294967295 then -- 超过4字节最大值, 重新开始
                        self.subid = 1
                    end
                    subid = self.subid
                    self.sq(function()
                        local handshake = string.pack(">I4s2", 0, string.format("B@%d@%d@OKK@E", subid, time))
                        local r = kcp:lkcp_send(handshake, from)
                        if r < 0 then
                            gLog.e("iSockServer:dispatch_msg do handshake error, from=", socketdriver.udp_address(from), "uid=", uid, "time=", time, "r=", r)
                            self.handshakeMap[uid] = nil
                            self.handshakeFrom[from] = nil
                            kcp = nil
                            return
                        else
                            kcp:lkcp_flush()
                        end
                    end)
                    -- 创建kcp, 用于业务
                    local kcp = self:getKcp(from, subid, uid)
                    -- 维护关联信息
                    self.connection[subid] = {
                        from = from,
                        subid = subid,
                        uid = uid,
                        kcp = kcp,
                        ip = socketdriver.udp_address(from),
                        ms = 0,
                        maxms = 600*1000,
                    }
                    self.connectNum = self.connectNum + 1
                    if self.uidMap[uid] then
                        local subid_ = self.uidMap[uid].subid
                        self.uidMap[uid] = nil
                        if self.connection[subid_] then
                            self.connection[subid_] = nil
                            self.connectNum = self.connectNum - 1
                        end
                    end
                    self.uidMap[uid] = self.connection[subid]
                    -- 持续保证业务kcp的可靠性, 直到kcp销毁, 一场战斗300秒, 此处让最多持续600秒
                    skynet.fork(function(_subid)
                        while(true) do
                            local u = self.connection[_subid]
                            if not u then
                                --gLog.d("iSockServer:dispatch_msg stop lkcp_update", _subid)
                                break
                            end
                            local ms = self:getms()
                            if ms > u.maxms then
                                --gLog.d("iSockServer:dispatch_msg stop lkcp_update", _subid)
                                break
                            end
                            local nexttime = self.sq(function()
                                return u.kcp:lkcp_check(ms)
                            end)
                            local diff = nexttime - ms
                            skynet.sleep(math.ceil((diff > 0 and diff or 20)/10)) -- lutil.isleep(diff)
                            self.sq(function()
                                ms = self:getms()
                                u.kcp:lkcp_update(ms)
                            end)
                        end
                    end, subid)
                    -- 3s=60*50ms=3000ms内保证回复握手包的可靠性
                    skynet.fork(function(uid)
                        for i=1,60,1 do
                            skynet.sleep(5) --50ms
                            --gLog.d("iSockServer:dispatch udp keep kcp i=", i, self.handshakeMap[uid] and self.handshakeMap[uid].time)
                            if self.handshakeMap[uid] then
                                self.sq(function()
                                    self.handshakeMap[uid].kcp:lkcp_update(self:getms())
                                end)
                            else
                                break
                            end
                        end
                        if self.handshakeMap[uid] then
                            self.handshakeFrom[self.handshakeMap[uid].from] = nil
                            self.handshakeMap[uid] = nil
                        end
                    end, uid)
                    gLog.i("iSockServer:dispatch udp do handshake ok, from=", socketdriver.udp_address(from), "subid=", subid, "uid=", uid, "time=", time, "subid=", subid)
                else
                    kcp = nil
                    gLog.w("iSockServer:dispatch udp do handshake fail, from=", socketdriver.udp_address(from), "subid=", subid, "uid=", uid, "time=", time, "subid=", subid, "arr=", arr[1], arr[2], arr[3], arr[4])
                end
            else
                gLog.i("iSockServer:dispatch udp do handshake repeat, from=", socketdriver.udp_address(from), "subid=", subid, "hrlen=", hrlen, "hr=", hr)
                kcp = nil
                -- 收到回复握手包的确认包
                if self.handshakeFrom[from] then
                    self.sq(function()
                        self.handshakeFrom[from].kcp:lkcp_input(str, from)
                    end)
                end
            end
        elseif subid > 0 then
            local u = self.connection[subid]
            if u then
                u.from = from
                local ms = self:getms()
                local nexttime = self.sq(function()
                    -- 若收到udp包, 则作为下层协议输入到kcp
                    u.kcp:lkcp_input(str, from)
                    -- 更新kcp, 获取并处理消息, 一个kcp帧最多执行1次update
                    return u.kcp:lkcp_check(ms)
                end)
                local diff = nexttime - ms
                if diff >= 0 then
                    u.ms = nexttime
                    skynet.sleep(math.ceil(diff/10)) -- lutil.isleep(diff)
                    if not u.ms then
                        gLog.d("iSockServer:dispatch udp return from=", socketdriver.udp_address(from), "subid=", self.subid, "uid=", u.uid, "nexttime=", nexttime)
                        return
                    end
                end
                self.sq(function()
                    ms = self:getms()
                    u.kcp:lkcp_update(ms)
                end)
                u.ms = nil
                while(1) do
                    local hrlen, hr = self.sq(function()
                        return u.kcp:lkcp_recv()
                    end)
                    --gLog.d("iSockServer:dispatch udp do3 from=", socketdriver.udp_address(from), "subid=", self.subid, "uid=", u.uid, "hrlen=", hrlen, "hr=", hr, "nexttime=", nexttime, ms, diff)
                    if hrlen > 0 then
                        self:request(subid, hr, hrlen)
                    else
                        break
                    end
                end
            else
                gLog.w("iSockServer:dispatch udp ignore2", subid, str)
            end
        else
            gLog.w("iSockServer:dispatch udp ignore3", subid, str)
        end
    else
        gLog.w("iSockServer:dispatch udp ignore5", subid, str)
    end
end

-- 处理消息 not atomic, may yield
function iSockServer:request(subid, msg, sz)
    --gLog.d("iSockServer:request subid=", subid, "msg=", msg, "sz=", sz)
    local ok, err = pcall(self.do_request, self, subid, msg, sz)
    if not ok then
        -- 协议异常, 关闭连接
        gLog.w("iSockServer:request error: invalid package", ok, err, "subid=", subid, "msg=", msg, "sz=", sz)
        if self.mode == eSocketMode.eTcp then
            self:close_tcp(subid, 1)
        else
            if self.connection[subid] then
                self:close(subid, 1)
            end
        end
    end
end

-- 处理消息
function iSockServer:do_request(subid, msg, sz)
    local u = assert(self.connection[subid], string.format("iSockServer:do_request error: invalid subid=%s", subid))
    local t, cmd, args, rsp = protoLib:c2sDecode(msg, sz)
    gLog.d("iSockServer:do_request request cmd=", cmd, "args=", table2string(args))
    local _, rsp = xpcall(function() -- NOTICE: YIELD here, socket may close.
        local f = assert(cmdCtrl[cmd], "iSockServer:do_request error, cmd= "..cmd.." is not found")
        if type(f) == "function" then
            return f(args)
        end
    end, svrFunc.exception)
    gLog.d("iSockServer:do_request rsp cmd=", cmd, "rsp=", table2string(rsp))
    -- the return subid may change by multi request, check connect
    if rsp and self.connection[subid] and u.subid == self.connection[subid].subid then
        self:response_msg(subid, rsp, cmd, rsp or {code = gErrDef.Err_SERVICE_EXCEPTION,})
    else
        gLog.w("iSockServer:do_request ignore subid=%d", u.subid, self.connection[subid] and self.connection[subid].subid, "cmd=", cmd, "args=", args)
    end
end

-- 回包
function iSockServer:response_msg(subid, rsp, cmd, msg)
    --gLog.d("iSockServer:response_msg subid=", subid, "cmd=", cmd, "msg=", msg)
    local u = self.connection[subid]
    if u then
        if self.mode == eSocketMode.eTcp then
            socketdriver.send(u.fd, netpack.pack(rsp(msg)))
        else
            self.sq(function()
                if self.mode == eSocketMode.eUdpKcp then
                    local package = rsp(msg)
                    u.kcp:lkcp_send(package, u.from)
                    u.kcp:lkcp_flush()
                elseif self.mode == eSocketMode.eUdpKcpFec then
                    local package = rsp(msg)
                    u.kcp:lkcp_send(package, u.from)
                    u.kcp:lkcp_flush()
                end
            end)
        end
    end
end

-- 推送消息给客户端
function iSockServer:send_msg(uid, cmd, msg, subid)
    local u = self.uidMap[uid] or self.connection[subid]
    if u then
        if self.mode == eSocketMode.eTcp then
            local package = protoLib:s2cEncode(cmd, msg, 0)
            socketdriver.send(u.fd, netpack.pack(package))
        else
            self.sq(function()
                gLog.d("iSockServer:send_msg", uid, cmd, msg, subid)
                if self.mode == eSocketMode.eUdpKcp then
                    local package = protoLib:s2cEncode(cmd, msg, 0)
                    local r = u.kcp:lkcp_send(package, u.from)
                    if r < 0 then
                        gLog.w("iSockServer:send_msg error", uid, cmd, msg, subid, "r=", r)
                        return
                    end
                    u.kcp:lkcp_flush()
                elseif self.mode == eSocketMode.eUdpKcpFec then
                    local package = protoLib:s2cEncode(cmd, msg, 0)
                    local r = u.kcp:lkcp_send(package, u.from)
                    if r < 0 then
                        gLog.w("iSockServer:send_msg error", uid, cmd, msg, subid, "r=", r)
                        return
                    end
                    u.kcp:lkcp_flush()
                end
            end)
        end
    end
end

-- 客户端断开
function iSockServer:close(subid, tag)
    gLog.i("iSockServer:close subid=", subid, tag)
    if self.connection[subid] then
        local u = self.connection[subid]
        u.sq(function()
            self.connection[subid] = nil
            self.uidMap[u.uid] = nil
            self.connectNum = self.connectNum - 1
        end)
        -- 推送关闭连接
        self:send_msg(u.uid, "syncCloseConnect", {subid = subid,})
    else
        gLog.w("iSockServer:close ignore", subid, tag)
    end
end

-- 获取当前时间(毫秒)
function iSockServer:getms()
    return math.floor(lutil.gettimeofday())
end

--[[
    注意: 因udp无连接, 上行报文大小最好<=一个mtu大小, 超过时由kcp将对其分片处理, 固此处无需考虑报文太大的问题, 过程如下:
         A          --原始报文-->
    hA1 hA2 hA3     --kcp将对其分3片, 并保证3片的可靠性-->
         A          --接收端kcp收到3片后, 组成得到原始报文
]]
function iSockServer:unpack_package(_text)
    local sz = #_text
    if sz < 6 then
        return nil, nil
    end
    if sz > 1464 then
        gLog.w("iSockServer:unpack_package package is big", sz)
    end
    local text = string.sub(_text, 5, -1)
    sz = #text
    local s = text:byte(1) * 256 + text:byte(2)
    if sz < s+2 then
        return nil, nil
    end
    local subid = string.unpack(">I4", _text, 1, 4)
    return subid, text:sub(3,2+s)
end

function iSockServer:udp_output(buf, from, subid)
    if from and subid then
        --gLog.d("iSockServer:udp_output udp_send, from=", socketdriver.udp_address(from), "subid=", subid, "buf=", buf, "[end]")
        socketdriver.udp_send(self.sock, from, string.pack(">I4s2", subid, buf))
    else
        gLog.w("iSockServer:udp_output error, from=", socketdriver.udp_address(from), "subid=", subid, "buf=", buf, "[end]")
    end
end

-- 创建kcp, 一条`连接`一个kcp
function iSockServer:getKcp(from, subid, uid)
    gLog.i("iSockServer:getKcp create ip=", socketdriver.udp_address(from), "subid=", subid, "uid=", uid)
    return self.sq(function()
        local kcp = lkcp.lkcp_create(self.sock, from, subid, function (buf)
            self:udp_output(buf, from, subid)
        end)
        -- 考虑到丢包重发, 设置最大收发窗口为128
        kcp:lkcp_wndsize(128, 128)
        -- 默认模式
        -- kcp:lkcp_nodelay(0, 20, 0, 0)
        -- 普通模式, 关闭流控等
        --kcp:lkcp_nodelay(0, 20, 0, 1)
        -- 快速模式, 第一个参数nodelay启用以后若干常规加速将启动;第二个参数interval为内部处理时钟,默认设置为 10ms;第三个参数 resend为快速重传指标,设置为2;第四个参数为是否禁用常规流控,这里禁止
         kcp:lkcp_nodelay(1, 20, 2, 1)
        -- 需要执行一下update
        kcp:lkcp_update(self:getms())
        return kcp
    end)
end

-------------------------------------------------------->>>
--------------------tcp mode begin---------------------->>>
-------------------------------------------------------->>>
-- 客户端连入
function iSockServer:open_tcp(fd, msg)
    gLog.d("iSockServer:open_tcp fd=", fd, "msg=", msg)
    -- 先断开fd
    self:close_tcp(fd, 2)
    -- 是否无延迟
    if self.nodelay then
        socketdriver.nodelay(fd)
    end
    -- 更新关联信息
    self.handshakeFd[fd] = msg --addr
    -- 开启套接字
    socketdriver.start(fd)
end

-- 分发消息
function iSockServer:dispatch_queue_tcp()
    local fd, msg, sz = netpack.pop(self.queue)
    if fd then
        -- may dispatch even the message blocked
        -- If the message never block, the queue should be empty, so only fork once and then exit.
        skynet.fork(function ()
            self:dispatch_queue_tcp()
        end)

        self:dispatch_msg_tcp(fd, msg, sz)

        for fd, msg, sz in netpack.pop, self.queue do
            self:dispatch_msg_tcp(fd, msg, sz)
        end
    end
end

-- 分发消息
function iSockServer:dispatch_msg_tcp(fd, msg, sz)
    gLog.d("iSockServer:dispatch_msg_tcp=", fd, msg, sz)
    if self.connection[fd] or self.handshakeFd[fd] then
        local addr = self.handshakeFd[fd]
        if addr then
            self:handshake(fd, addr, msg, sz)
            self.handshakeFd[fd] = nil
        else
            self:request(fd, msg, sz)
        end
    else
        gLog.w(string.format("iSockServer:dispatch_msg_tcp drop message from fd (%d) : %s", fd, netpack.tostring(msg, sz)))
    end
end

-- 客户端断开
function iSockServer:close_tcp(fd, tag)
    --gLog.d("iSockServer:close_tcp fd=", fd, "tag=", tag)
    local flag = false
    if self.handshakeFd[fd] then
        flag = true
        self.handshakeFd[fd] = nil
    end
    local uid = self.connection[fd] and self.connection[fd].uid
    if self.connection[fd] then
        flag = true
        self.connection[fd] = nil
        self.connectNum = self.connectNum - 1
        self.uidMap[uid] = nil
    end
    if flag then
        socketdriver.close(fd)
        gLog.i("iSockServer:close_tcp ok, fd=", fd, "uid=", uid, "tag=", tag)
    end
end

-- 认证 atomic, not yield
function iSockServer:handshake(fd, addr, msg, sz)
    local str = netpack.tostring(msg, sz)
    gLog.d("iSockServer:handshake begin, fd=", fd, addr, "str=", str, "sz=", sz)
    local pcallok, ok, result, rsp = xpcall(function()
        local t, cmd, args, rsp = protoLib:c2sDecode(msg, sz)
        gLog.d("iSockServer:handshake do fd=", fd, addr, "subid, uid, time=", args.subid, args.uid, args.time)
        local subid, uid, time = args.subid, args.uid, args.time
        if cmd ~= "reqHandshake" or not subid or subid ~= 0 or not uid or uid <= 0 or not time or time <= 0 then
            gLog.w("iSockServer:handshake error1", fd, uid, t, cmd, args)
            return false, {code = 401, text = "401 unauthorized",}
        end
        -- 检查连接版本号
        local u = self.uidMap[uid]
        if time <= (u and u.time or 0) then
            gLog.w("iSockServer:handshake error2", fd, uid)
            return false, {code = 403, text = "403 time expired",}
        end
        -- 检查连接数
        if self.connectNum >= self.connectMax then
            gLog.w("iSockServer:handshake error4", fd, uid)
            return false, {code = 405, text = "405 connect num limit",}
        end
        -- 顶号时先关闭之前的连接
        if u then
            gLog.w("iSockServer:handshake error5", fd, uid, u.fd)
            self:close_tcp(u.fd, 3)
        end
        -- 自增subid
        self.subid = self.subid + 1
        if self.subid >= 4294967295 then -- 超过4字节最大值, 重新开始
            self.subid = 1
        end
        subid = self.subid
        -- 更新关联信息
        self.connection[fd] = {
            fd = fd,
            subid = subid,
            uid = uid,
            addr = addr,
            time = time,
        }
        self.uidMap[uid] = self.connection[fd]
        self.connectNum = self.connectNum + 1
        gLog.i("iSockServer:handshake ok, fd=", fd, "subid=", subid, "uid=", uid, "time=", time, "subid=", subid, "addr=", addr)
        return true, {code = 200, text = "200 OK", subid = subid, uid = uid, time = time,}, rsp
    end, svrFunc.exception)
    if not pcallok or not ok then
        gLog.w("iSockServer:handshake error1", fd)
        result = {code = 400, text = "400 Bad Request",}
    end
    -- 回包
    if rsp then
        socketdriver.send(fd, netpack.pack(rsp(result)))
    end
    -- 若认证失败, 则关闭连接
    if not pcallok or not ok then
        self:close_tcp(fd, 4)
    end
end
--------------------------------------------------------<<<
---------------------tcp mode end-----------------------<<<
--------------------------------------------------------<<<

return iSockServer
