//
// Created by gels on 2023/6/26.
//
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include "include/enet.h"
#include <string.h>
#include <memory.h>

int main() {
    fprintf(stderr, "=====start testclient====\n");
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        return EXIT_FAILURE;
    }

    ENetHost * client;

    client = enet_host_create (NULL /* create a client host */,
                               1 /* only allow 1 outgoing connection */,
                               2 /* allow up 2 channels to be used, 0 and 1 */,
                               0 /* assume any amount of incoming bandwidth */,
                               0 /* assume any amount of outgoing bandwidth */);

    if (client == NULL)
    {
        fprintf (stderr,
                 "An error occurred while trying to create an ENet client host.\n");
        exit (EXIT_FAILURE);
    }

    ENetAddress address;
    ENetEvent event;
    ENetPeer *peer;

    /* Connect to some.server.net:1234. */
    //char host[64] = "172.16.10.200";
    char host[64] = "127.0.0.1";
    int port = 1234;
    enet_address_set_host (& address, host);
    address.port = port;

    /* Initiate the connection, allocating the two channels 0 and 1. */
    peer = enet_host_connect (client, & address, 2, 34);

    if (peer == NULL)
    {
        fprintf (stderr,"No available peers for initiating an ENet connection.\n");
        exit (EXIT_FAILURE);
    }
    /* Wait up to 5 seconds for the connection attempt to succeed. */
    if (enet_host_service (client, & event, 5000) > 0 && event.type == ENET_EVENT_TYPE_CONNECT)
    {
        fprintf(stdout, "Connection to %s:%d succeeded.\n", host, port);

        int i = 0;
        int r = 0;
        /* Create a reliable packet of size containing "handshake\0" */
        char str1[512]  = "{\"cmd\":\"handshake\",\"data\":{\"hmac\":\"6vC0lXGsc5tnP8VIH8xuT2FtSko=\",\"uid\":1201,\"index\":1}}";
        ENetPacket * packet = enet_packet_create (str1, strlen (str1) + 1, ENET_PACKET_FLAG_RELIABLE);
        while(1) {
            //do handshake
            if (i == 0) {
                /* Extend the packet so and append the string "i=xxx", so it now contains "handshake i=xxx\0*/
//                char str2[64] = {0};
//                sprintf(str2, " i=%d", i);
//                enet_packet_resize (packet, strlen (str1) + strlen(str2) + 1);
//                strcpy (& packet -> data [strlen (str1)], str2);

                /* Send the packet to the peer over channel id 0. */
                /* One could also broadcast the packet by         */
                /* enet_host_broadcast (host, 0, packet);         */
                fprintf(stdout, "client enet_peer_send sz=%d msg=%s\n", packet->dataLength, (char *)packet->data);
                enet_peer_send (peer, 0, packet);
                enet_peer_send (peer, 0, packet);
                /* One could just use enet_host_service() instead. */
                //enet_host_flush (client);
            }
            i++;
            while ((r = enet_host_service(client, &event, 0)) > 0) {
                switch (event.type) {
                    case ENET_EVENT_TYPE_RECEIVE:
                        printf("client receive packet of length= %u data= %s was received from %s on channel %u.\n",
                               event.packet->dataLength,
                               (char*)event.packet->data,
                               event.peer->data,
                               event.channelID);

                        /* Clean up the packet now that we're done using it. */
                        enet_packet_destroy(event.packet);
                        break;

                    case ENET_EVENT_TYPE_DISCONNECT:
                        printf("client disconnected uid=%d\n", *((enet_uint32 *)event.peer->data));

                        /* Reset the peer's client information. */
                        event.peer->data = NULL;
                        break;
                }
            }
            if (r < 0) {
                fprintf(stderr, "client enet_host_service error\n");
                break;
            }
            usleep(100000);
        }
        enet_packet_destroy(packet);
    }
    else
    {
        /* Either the 5 seconds are up or a disconnect event was */
        /* received. Reset the peer in the event the 5 seconds   */
        /* had run out without any significant event.            */
        enet_peer_reset (peer);

        fprintf(stdout, "Connection to %s:%d failed.\n", host, port);
    }


    enet_host_destroy(client);

    atexit (enet_deinitialize);
    return 0;
}

