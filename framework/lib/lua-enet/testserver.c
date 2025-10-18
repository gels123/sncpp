//
// Created by gels on 2023/6/26.
//
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "include/enet.h"

int main() {
    fprintf(stderr, "=====start testserver====\n");
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        return EXIT_FAILURE;
    }

    ENetAddress address;
    ENetHost * server;

    /* Bind the server to the default localhost.     */
    /* A specific host address can be specified by   */
    /* enet_address_set_host (& address, "x.x.x.x"); */

    //address.host = ENET_HOST_ANY;
    enet_address_set_host (& address, "0.0.0.0");
    /* Bind the server to port 1234. */
    address.port = 1234;

    server = enet_host_create (& address /* the address to bind the server host to */,
                               3      /* allow up to 32 clients and/or outgoing connections */,
                               0      /* allow up to 2 channels to be used, 0 and 1 */,
                               0      /* assume any amount of incoming bandwidth */,
                               0      /* assume any amount of outgoing bandwidth */);
    if (server == NULL)
    {
        fprintf (stderr,"An error occurred while trying to create an ENet server host.\n");
        exit (EXIT_FAILURE);
    }

    ENetEvent event;

    int end = 0;
    /* Wait up to 1000 milliseconds for an event. */
    while(1) {
        fprintf(stdout, "do while loop\n");
        while (enet_host_service(server, &event, 0) > 0) {
            switch (event.type) {
                case ENET_EVENT_TYPE_CONNECT:
                    printf("A new client connected from %x:%u event.data=%d\n", event.peer->address.host, event.peer->address.port, event.data);

                    /* Store any relevant client information here. */
                    event.peer->data = "Client information";

                    break;

                case ENET_EVENT_TYPE_RECEIVE:
                    printf("server receive packet of length= %u data= %s was received from %s on channel %u.\n",
                           event.packet->dataLength,
                           event.packet->data,
                           event.peer->data,
                           event.channelID);

                    /* Clean up the packet now that we're done using it. */
                    enet_packet_destroy(event.packet);
                    break;

                case ENET_EVENT_TYPE_DISCONNECT:
                    printf("%s disconnected.\n", event.peer->data);

                    /* Reset the peer's client information. */
                    event.peer->data = NULL;
                    break;
            }
        }
        if(end) {
            break;
        }
        usleep(100000);
    }


    enet_host_destroy(server);

    atexit (enet_deinitialize);
    return 0;
}

