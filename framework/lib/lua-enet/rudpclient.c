//
// Created by gels on 2023/6/26.
//
#include "include/enet.h"
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
#include <memory.h>


static int lconnect(lua_State *L) {
    size_t hostsz = 0;
    const char* host = luaL_checklstring(L, 1, &hostsz);
    int port = luaL_checkinteger(L, 2);
    if (host == NULL || hostsz <= 0 || port <= 0) {
        return luaL_error(L, "lconnect error host or port invalid\n");
    }
    //fprintf(stdout, "lconnect host=%s port=%d\n", host, port);

    if (enet_initialize () != 0) {
        return luaL_error(L, "lconnect error enet_initialize\n");
    }

    ENetHost *client = enet_host_create (NULL, 1, 2, 0, 0);
    if (client == NULL) {
        return luaL_error(L, "lconnect error enet_host_create\n");
    }

    ENetAddress address;
    ENetEvent event;
    ENetPeer *peer;

    enet_address_set_host (& address, host);
    address.port = port;

    /* Initiate the connection, allocating the 0 channel. */
    peer = enet_host_connect (client, & address, 0, 0);
    if (peer == NULL)
    {
        return luaL_error(L, "lconnect error enet_host_connect\n");
    }
    /* Wait up to 5 seconds for the connection attempt to succeed. */
    if (enet_host_service (client, & event, 5000) > 0 && event.type == ENET_EVENT_TYPE_CONNECT)
    {
        fprintf(stdout, "lconnect to %s:%d succeeded.\n", host, port);
        lua_pushlightuserdata(L, peer);
        return 1;
    } else {
        /* Either the 5 seconds are up or a disconnect event was */
        /* received. Reset the peer in the event the 5 seconds   */
        /* had run out without any significant event.            */
        enet_peer_reset (peer);
        return luaL_error(L, "lconnect error connect\n");
    }
}

static int lrecv(lua_State *L) {
    ENetPeer *peer = lua_touserdata(L, 1);
    if (peer == NULL || peer->host == NULL) {
        return luaL_error(L, "lrecv error peer=%p\n", (void*)peer);
    }
    ENetEvent event;
    int r = enet_host_service(peer->host, &event, 0);
    if (r > 0) {
        switch (event.type) {
            case ENET_EVENT_TYPE_RECEIVE:
                //printf("lrecv receive packet of length= %u data= %s\n", (unsigned int)event.packet->dataLength, (char*)event.packet->data);
                lua_pushlstring(L, (const char*)event.packet->data, event.packet->dataLength);
                /* Clean up the packet now that we're done using it. */
                enet_packet_destroy(event.packet);
                return 1;
            case ENET_EVENT_TYPE_DISCONNECT:
                fprintf(stdout, "lrecv disconnect peer=%p\n", (void*)event.peer);
                lua_pushliteral(L, "");
                // close
                return 1;
            default:
                fprintf(stdout, "lrecv type=%d\n", event.type);
                return 0;
        }
    } else if (r == 0) {
        return 0;
    } else {
        return luaL_error(L, "socket error: %s", strerror(errno));
    }
}

static int lsend(lua_State *L) {
    ENetPeer *peer = lua_touserdata(L, 1);
    size_t sz = 0;
    const char* msg = luaL_checklstring(L, 2, &sz);
    if (peer == NULL || peer->host == NULL || msg == NULL || sz <= 0) {
        return luaL_error(L, "lsend error peer=%p\n", (void*)peer);
    }
    ENetPacket * packet = enet_packet_create (msg, sz + 1, ENET_PACKET_FLAG_RELIABLE);
    //fprintf(stdout, "lsend sz=%d msg=%s\n", (int)packet->dataLength, (char *)packet->data);
    int r = enet_peer_send (peer, 0, packet);
    if (r == 0) {
        enet_host_flush (peer->host);
    } else {
        enet_packet_destroy(packet);
    }
    lua_pushinteger(L, r);
    return 1;
}

static int lclose(lua_State *L) {
    ENetPeer *peer = lua_touserdata(L, 1);
    if (peer == NULL || peer->host == NULL) {
        return 0;
    }
    fprintf(stdout, "close peer=%p\n", (void*)peer);
    enet_peer_disconnect (peer, 0);
    return 0;
}

int luaopen_rudpclient(lua_State *L) {
    luaL_Reg reg[] = {
            {"connect", lconnect},
            {"recv", lrecv},
            {"send", lsend},
            {"close", lclose},
            {NULL, NULL}
    };
    luaL_newlib(L, reg);
    return 1;
}
