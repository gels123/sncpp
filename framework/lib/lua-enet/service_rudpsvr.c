#include "lua.h"
#include "lauxlib.h"
#include "skynet.h"
#include "skynet_handle.h"
#include "skynet_mq.h"
#include "skynet_server.h"
#include "skynet_malloc.h"
#include "include/enet.h"
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <signal.h>
#include <pthread.h>
#include <assert.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct request_close_t {
    int flag;
} request_close_t;

typedef struct request_sendbuffer_t {
    ENetPeer *peer;
    ENetPacket *packet;
} request_sendbuffer_t;

typedef struct request_disconnect_t {
    ENetPeer *peer;
} request_disconnect_t;

typedef struct request_msg_t {
    uint8_t type;
    union {
        request_close_t c;
        request_sendbuffer_t s;
        request_disconnect_t d;
    } u;
} request_msg_t;

typedef struct rudpsvr_t {
    ENetAddress address;
    ENetHost *host;
    int recvctrl_fd;
    int sendctrl_fd;
    fd_set rfds;
    uint32_t handler;
} rudpsvr_t;

typedef struct rudp_socket_msg_t {
    int t; //1=connect 2=disconnect 3=receive
    ENetPeer *peer;
    ENetPacket *packet;
} rudp_socket_msg_t;

void send_request(rudpsvr_t *inst, request_msg_t *request, char type, int len) {
    //fprintf(stdout, "rudpsvr send_request inst=%p type=%c len=%d\n", (void *)inst, type, len);
    request->type = type;
    const char * req = (const char *)request;
    for (;;) {
        ssize_t n = write(inst->sendctrl_fd, req, len);
        if (n < 0) {
            if (errno != EINTR) {
                fprintf(stderr, "send_request: send ctrl command error %s.\n", strerror(errno));
            }
            continue;
        }
        assert(n == len);
        return;
    }
}

int has_cmd(struct rudpsvr_t *inst) {
    struct timeval tv = {0,0};

    FD_SET(inst->recvctrl_fd, &inst->rfds);

    int val = select(inst->recvctrl_fd+1, &inst->rfds, NULL, NULL, &tv);
    if (val == 1) {
        return 1;
    }
    return 0;
}

void block_readpipe(int pipefd, void *buffer, int sz) {
    for (;;) {
        int n = read(pipefd, buffer, sz);
        if (n<0) {
            if (errno == EINTR)
                continue;
            fprintf(stderr, "service_rudpsvr block_readpipe: read pipe error %s.\n", strerror(errno));
            return;
        }
        // must atomic read from a pipe
        assert(n == sz);
        return;
    }
}

int ctrl_cmd(struct rudpsvr_t *inst) {
    int fd = inst->recvctrl_fd;
    // the length of message is one byte, so 256+8 buffer size is enough.
    size_t len = sizeof(request_msg_t);
    uint8_t buffer[len];
    block_readpipe(fd, buffer, len);
    // ctrl command only exist in local fd, so don't worry about endian.
    request_msg_t *req = (request_msg_t*)buffer;
    switch (req->type) {
        case 'C': {
            fprintf(stdout, "service_rudpsvr ctrl_cmd C, type=%d flag=%d\n", req->type, req->u.c.flag);
            if (inst->host) {
                enet_host_destroy(inst->host);
                atexit(enet_deinitialize);
                inst->host = NULL;
            }
            if (inst->recvctrl_fd > 0) {
                close(inst->recvctrl_fd);
            }
            if (inst->sendctrl_fd > 0) {
                close(inst->sendctrl_fd);
            }
            skynet_free(inst);
            return -1;
        }
        case 'S': {
            //fprintf(stdout, "service_rudpsvr ctrl_cmd S, type=%d sz=%d data=%s \n", req->type, (int)req->u.s.packet->dataLength, (char*)req->u.s.packet->data);
            if (req->u.s.peer && req->u.s.packet) {
                if (enet_peer_send (req->u.s.peer, 0, req->u.s.packet) != 0) {
                    fprintf(stderr, "service_rudpsvr ctrl_cmd S enet_peer_send error\n");
                    enet_packet_destroy(req->u.s.packet);
                }
            } else {
                fprintf(stderr, "service_rudpsvr ctrl_cmd S error\n");
            }
            return 0;
        }
        case 'D' : {
            if (req->u.d.peer) {
                fprintf(stdout, "service_rudpsvr ctrl_cmd D, type=%d %x:%u\n", req->type, req->u.d.peer->address.host, req->u.d.peer->address.port);
                enet_peer_disconnect_later (req->u.d.peer, 0);
            } else {
                fprintf(stderr, "service_rudpsvr ctrl_cmd D error\n");
            }
            return 0;
        }
        default:
            fprintf(stderr, "service_rudpsvr ctrl_cmd: Unknown type %c.\n", req->type);
            return 0;
    };
    return 0;
}

void * _poll(void * ud) {
    rudpsvr_t *inst = (rudpsvr_t *)ud;
    ENetHost *host = inst->host;
    ENetEvent event;

    int r = 0;
    rudp_socket_msg_t *sm;
    size_t sz = sizeof(*sm);
    struct skynet_message message;
    fprintf(stdout, "rudpsvr _poll host=%p port=%d\n", (void *)host, host->address.port);
    for (;;) {
        if (has_cmd(inst)) {
            int type = ctrl_cmd(inst);
            if (type != 0) {
                fprintf(stdout, "rudpsvr _poll ctrl_cmd error, type=%d host=%p\n", type, (void *)host);
                return NULL;
            } else {
                continue;
            }
        }
        //fprintf(stdout, "service_rudpsvr _poll loop\n");
        while ((r = enet_host_service(host, &event, 0)) > 0) {
            switch (event.type) {
                case ENET_EVENT_TYPE_CONNECT:
                    fprintf(stdout, "rudpsvr connected %x:%u handler=%u\n", event.peer->address.host, event.peer->address.port, inst->handler);
                    /* Store any relevant client information here. */
                    event.peer->data = (void*) inst;

                    sm = (rudp_socket_msg_t *)skynet_malloc(sz); //free at function dispatch_message()
                    sm->t = ENET_EVENT_TYPE_CONNECT;
                    sm->peer = event.peer;
                    sm->packet = NULL;

                    message.source = 0;
                    message.session = 0;
                    message.data = sm;
                    message.sz = sz | ((size_t)PTYPE_SOCKET << MESSAGE_TYPE_SHIFT);

                    if (skynet_context_push(inst->handler, &message)) {
                        fprintf(stderr, "rudpsvr connected error %x:%u handler=%u\n", event.peer->address.host, event.peer->address.port, inst->handler);
                        // todo: report somewhere to close socket
                        skynet_free(sm);
                    }
                    break;

                case ENET_EVENT_TYPE_RECEIVE:
                    //fprintf(stdout, "rudpsvr receive %x:%u sz=%d data=%s\n", event.peer->address.host, event.peer->address.port, (int)event.packet->dataLength, event.packet->data);
                    sm = (rudp_socket_msg_t *)skynet_malloc(sz); //free at dispatch_message()
                    sm->t = ENET_EVENT_TYPE_RECEIVE;
                    sm->peer = event.peer;
                    sm->packet = event.packet;

                    message.source = 0;
                    message.session = 0;
                    message.data = sm;
                    message.sz = sz | ((size_t)PTYPE_SOCKET << MESSAGE_TYPE_SHIFT);

                    if (skynet_context_push(inst->handler, &message)) {
                        fprintf(stderr, "rudpsvr receive error %x:%u handler=%u\n", event.peer->address.host, event.peer->address.port, inst->handler);
                        // todo: report somewhere to close socket
                        enet_packet_destroy(sm->packet);
                        skynet_free(sm);
                    }
                    /* Clean up the packet now that we're done using it. */
                    //enet_packet_destroy(event.packet);
                    break;

                case ENET_EVENT_TYPE_DISCONNECT:
                    fprintf(stdout, "rudpsvr disconnect %x:%u handler=%u\n", event.peer->address.host, event.peer->address.port, inst->handler);
                    sm = (rudp_socket_msg_t *)skynet_malloc(sz); //free at dispatch_message()
                    sm->t = ENET_EVENT_TYPE_DISCONNECT;
                    sm->peer = event.peer;
                    sm->packet = NULL;

                    message.source = 0;
                    message.session = 0;
                    message.data = sm;
                    message.sz = sz | ((size_t)PTYPE_SOCKET << MESSAGE_TYPE_SHIFT);

                    if (skynet_context_push(inst->handler, &message)) {
                        fprintf(stderr, "rudpsvr disconnect error %x:%u handler=%u\n", event.peer->address.host, event.peer->address.port, inst->handler);
                        // todo: report somewhere to close socket
                        skynet_free(sm);
                    }
                    break;

                default:
                    break;
            }
        }
        if (r < 0) {
            fprintf(stderr, "rudpsvr _poll error, r=%d host=%p port=%d\n", r, (void *)host, host->address.port);
            break;
        }
        usleep(5000);//1000000=1s, 5000=5ms
    }
    return NULL;
}

extern struct rudpsvr_t * rudpsvr_create(void) {
	struct rudpsvr_t *inst = skynet_malloc(sizeof(*inst));
    memset(inst, 0, sizeof(*inst));
    return inst;
}

extern void rudpsvr_release(struct rudpsvr_t * inst) {
    fprintf(stderr, "rudpsvr_release inst=%p host=%p port=%d handler=%d recvctrl_fd=%d sendctrl_fd=%d\n", (void*)inst, (void*)inst->host, inst->address.port, inst->handler, inst->recvctrl_fd, inst->sendctrl_fd);

    request_msg_t request;
    memset(&request, 0, sizeof(request));
    request.u.c.flag = 1;
    send_request(inst, &request, 'C', sizeof(request));
}

extern int getnumbercount(uint32_t n) {
    int count = 0;
    while (n != 0) {
        n = n / 10;
        ++count;
    }
    return count;
}

extern void callbackmessage(void *ud, uint32_t watcher, uint32_t marker) {
    struct skynet_context *ctx = ud;
    size_t sz = getnumbercount(watcher) + getnumbercount(marker) + strlen("aoicallback") + 2;
    char *msg = skynet_malloc(sz);
    memset(msg, 0, sz);
    sprintf(msg, "aoicallback %d %d", watcher, marker);
    //caoi server的启动在laoi启动之后，handle理论是caoi = laoi + 1
    //如果失败,就需要换方式了
    skynet_send(ctx, 0, skynet_current_handle() - 1, PTYPE_TEXT | PTYPE_TAG_DONTCOPY, 0, (void *)msg, sz);
}

extern char* _parm(char *msg, int sz, int command_sz) {
    while (command_sz < sz) {
        if (msg[command_sz] != ' ')
            break;
        ++command_sz;
    }
    int i;
    for (i = command_sz; i < sz; i++) {
        msg[i - command_sz] = msg[i];
    }
    msg[i - command_sz] = '\0';
    return msg;
}

extern void _ctrl(struct skynet_context *ctx, struct rudpsvr_t *inst, const void *msg, int sz) {
//    char tmp[sz + 1];
//    memcpy(tmp, msg, sz);
//    tmp[sz] = '\0';
//    char *command = tmp;
//    int i;
//    if (sz == 0)
//        return;
//    for (i = 0; i < sz; i++) {
//        if (command[i] == ' ') {
//            break;
//        }
//    }
//    if (memcmp(command, "update", i) == 0) {
//        _parm(tmp, sz, i);
//        char *text = tmp;
//        char *idstr = strsep(&text, " ");
//        if (text == NULL) {
//            return;
//        }
//        int id = strtol(idstr, NULL, 10);
//        char *mode = strsep(&text, " ");
//        if (text == NULL) {
//            return;
//        }
//        float pos[3] = {0};
//        char *posstr = strsep(&text, " ");
//        if (text == NULL) {
//            return;
//        }
//        pos[0] = strtof(posstr, NULL);
//        posstr = strsep(&text, " ");
//        if (text == NULL) {
//            return;
//        }
//        pos[1] = strtof(posstr, NULL);
//        posstr = strsep(&text, " ");
//        pos[2] = strtof(posstr, NULL);
//        return;
//    }
//    skynet_error(ctx, "[rudpsvr] Unkown command : %s", command);
}

extern int rudpsvr_cb(struct skynet_context *context, void *ud, int type, int session, uint32_t source, const void *msg, size_t sz) {
    struct rudpsvr_t * inst = ud;
    fprintf(stdout, "rudpsvr_cb inst=%p type=%d sz=%d msg=%s\n", (void *)inst, type, (int)sz, (char*)msg);
	switch (type) {
        case PTYPE_TEXT:
            _ctrl(context, inst, msg, (int)sz);
            break;
	}
	return 0;
}

//@parm  port and handler split with ' '. ret 0 success, ret -1 fail
extern int rudpsvr_init(struct rudpsvr_t *inst, struct skynet_context *ctx, const char *parm) {
    fprintf(stdout, "rudpsvr_init inst=%p parm=%s\n", (void *)inst, parm);
    if (parm == NULL || strlen(parm) <= 0) {
        fprintf(stderr, "rudpsvr_init error: no parm to port.\n");
        return -1;
    }
    int sz = strlen(parm);
    char tmp[sz + 1];
    memcpy(tmp, parm, sz);
    tmp[sz] = '\0';
    int i;

    for (i = 0; i < sz; i++) {
        if (tmp[i] == ' ') {
            break;
        }
    }
    char host[i+1];
    memset(host, 0, sizeof(host));
    strncpy(host, tmp, i);
    _parm(tmp, sz, i);

    for (i = 0; i < sz; i++) {
        if (tmp[i] == ' ') {
            break;
        }
    }
    char port_s[i+1];
    memset(port_s, 0, sizeof(port_s));
    strncpy(port_s, tmp, i);
    _parm(tmp, sz, i);
    int port = atoi(port_s);
    if (port <= 0) {
        fprintf(stderr, "rudpsvr_init error: port invalid.\n");
        return -1;
    }

    int handler = atoi(tmp);
    if (handler <= 0) {
        fprintf(stderr, "rudpsvr_init error: handler invalid.\n");
        return -1;
    }
    inst->handler = handler;

    if (enet_initialize() != 0) {
        fprintf(stderr, "rudpsvr_init error: enet_initialize fail.\n");
        return -1;
    }
    if (enet_address_set_host(&inst->address, "0.0.0.0") != 0) {
        fprintf(stderr, "rudpsvr_init error: enet_address_set_host fail.\n");
        return -1;
    }
    inst->address.port = port;

    inst->host = enet_host_create(&inst->address, 4010, 1, 0, 0);
    if(inst->host == NULL) {
        fprintf(stderr, "rudpsvr_init error: enet_host_create fail.\n");
        return -1;
    }

    int fd[2]; //fd[0] to read and fd[1] to write
    if (pipe(fd)) {
        fprintf(stderr, "rudpsvr_init error: enet_host_create fail.\n");
        return -1;
    }
    inst->recvctrl_fd = fd[0];
    inst->sendctrl_fd = fd[1];
    FD_ZERO(&inst->rfds);
    assert(inst->recvctrl_fd < FD_SETSIZE);

    pthread_t pid;
    if (pthread_create(&pid, NULL, _poll, inst) != 0) {
        fprintf(stderr, "rudpsvr_init error: pthread_create fail.\n");
        close(fd[0]);
        inst->recvctrl_fd = 0;
        close(fd[1]);
        inst->sendctrl_fd = 0;
        return -1;
    }
    fprintf(stderr, "rudpsvr_init end inst=%p host=%s %p port=%d handler=%d recvctrl_fd=%d sendctrl_fd=%d\n", (void*)inst, host, (void*)inst->host, inst->address.port, inst->handler, inst->recvctrl_fd, inst->sendctrl_fd);

    skynet_callback(ctx, inst, rudpsvr_cb);
    return 0;
}

static int lrudpsvr_unpack(lua_State *L) {
    rudp_socket_msg_t *sm = lua_touserdata(L,1);
    int sz = luaL_checkinteger(L,2);
    //fprintf(stdout, "lrudpsvr_unpack sz=%d\n", sz);
    if (sm == NULL || sz != sizeof(*sm) || sm->peer == NULL) {
        if (sm->packet) {
            enet_packet_destroy(sm->packet);
            sm->packet = NULL;
        }
        return luaL_error(L, "lrudpsvr_unpack error sm=%p sz=%d\n", (void*)sm, sz);
    }
    lua_pushinteger(L, sm->t);
    lua_pushlightuserdata(L, sm->peer);
    if (sm->packet) {
        //fprintf(stdout, "lrudpsvr_unpack %x:%u t=%d sz=%d buf=%s\n", sm->peer->address.host, sm->peer->address.port, sm->t, (int)sm->packet->dataLength, (char *)sm->packet->data);
        lua_pushlstring(L, (const char*)sm->packet->data, sm->packet->dataLength);
        lua_pushinteger(L, sm->packet->dataLength);
        enet_packet_destroy(sm->packet);
        sm->packet = NULL;
        sm->peer = NULL;
        return 4;
    } else {
        //fprintf(stdout, "lrudpsvr_unpack %x:%u t=%d\n", sm->peer->address.host, sm->peer->address.port, sm->t);
        lua_pushlightuserdata(L, &sm->peer->address);
        sm->peer = NULL;
        return 3;
    }
}

static int lrudp_send(lua_State *L) {
    ENetPeer *peer = lua_touserdata(L,1);
    size_t sz = 0;
    const char* msg = luaL_checklstring(L, 2, &sz);
    if (peer == NULL || msg == NULL || sz <= 0) {
        return luaL_error(L, "lrudp_send error peer=%p\n", (void*)peer);
    }
    request_msg_t request;
    memset(&request, 0, sizeof(request));
    request.u.s.peer = peer;
    request.u.s.packet = enet_packet_create (msg, sz + 1, ENET_PACKET_FLAG_RELIABLE);
    if (request.u.s.packet) {
        send_request(peer->data, &request, 'S', sizeof(request));
    } else {
        return luaL_error(L, "lrudp_send error peer=%p\n", (void*)peer);
    }
    return 0;
}

static int lrudp_close(lua_State *L) {
    ENetPeer *peer = lua_touserdata(L, 1);
    if (peer == NULL || peer->host == NULL) {
        return luaL_error(L, "lclose error peer=%p\n", (void*)peer);
    }
    request_msg_t request;
    memset(&request, 0, sizeof(request));
    request.u.d.peer = peer;
    send_request(peer->data, &request, 'D', sizeof(request));
    return 0;
}

int luaopen_rudpsvr(lua_State *L) {
    luaL_Reg reg[] = {
            {"rudp_unpack", lrudpsvr_unpack},
            {"rudp_send", lrudp_send},
            {"rudp_close", lrudp_close},
            {NULL, NULL}
    };
    luaL_newlib(L, reg);
    return 1;
}

#ifdef __cplusplus
};
#endif