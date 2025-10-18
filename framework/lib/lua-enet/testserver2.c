//
// Created by gels on 2023/6/26.
//
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include "include/enet.h"

typedef struct rudpsvr_t {
    ENetAddress address;
    ENetHost *host;
} rudpsvr_t;

void * _poll(void * ud) {
    /* Wait up to 1000 milliseconds for an event. */
    rudpsvr_t *p = (rudpsvr_t *)ud;
    ENetEvent event;
    int r = 0;
    while(1) {
        //fprintf(stdout, "do while loop\n");
        while ((r = enet_host_service(p->host, &event, 0)) > 0) {
            switch (event.type) {
                case ENET_EVENT_TYPE_CONNECT:
                    printf("A new client connected from %x:%u event.data=%d\n", event.peer->address.host, event.peer->address.port, event.data);

                    /* Store any relevant client information here. */
                    event.peer->data = "Client information";

                    break;

                case ENET_EVENT_TYPE_RECEIVE:
                    printf("host receive packet of length= %u data= %s was received from %s on channel %u.\n",
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
        if (r < 0) {
            break;
        }
        usleep(10000);//1000000=1s
    }
//    sleep(5);
    fprintf(stdout, "_poll end\n");
    return NULL;
}

#define QUEUE_SIZE 1024

struct queue {
    pthread_mutex_t lock;
    int head;
    int tail;
    char * queue[QUEUE_SIZE];
};

void* readline_stdin(void* arg) {
    struct queue * q = arg;
    char tmp[1024];
    while (!feof(stdin)) {
        if (fgets(tmp,sizeof(tmp),stdin) == NULL) {
            // read stdin failed
            exit(1);
        }
        int n = strlen(tmp) -1;

        char * str = malloc(n+1);
        memcpy(str, tmp, n);
        str[n] = 0;

        pthread_mutex_lock(&q->lock);
        q->queue[q->tail] = str;

        if (++q->tail >= QUEUE_SIZE) {
            q->tail = 0;
        }
        if (q->head == q->tail) {
            // queue overflow
            exit(1);
        }
        pthread_mutex_unlock(&q->lock);
    }
    return NULL;
}

int main() {
    fprintf(stderr, "=====start testserver====\n");
    if (enet_initialize () != 0)
    {
        fprintf (stderr, "An error occurred while initializing ENet.\n");
        return EXIT_FAILURE;
    }

    rudpsvr_t *inst = malloc(sizeof(rudpsvr_t));
    memset(inst, 0, sizeof(rudpsvr_t));


    /* Bind the host to the default localhost.     */
    /* A specific host address can be specified by   */
    /* enet_address_set_host (& address, "x.x.x.x"); */

    //address.host = ENET_HOST_ANY;
    enet_address_set_host (& inst->address, "0.0.0.0");
    /* Bind the host to port 1234. */
    inst->address.port = 1234;

    inst->host = enet_host_create (& inst->address /* the address to bind the host host to */,
                               3      /* allow up to 32 clients and/or outgoing connections */,
                               0      /* allow up to 2 channels to be used, 0 and 1 */,
                               0      /* assume any amount of incoming bandwidth */,
                               0      /* assume any amount of outgoing bandwidth */);
    if (inst->host == NULL)
    {
        fprintf (stderr,"An error occurred while trying to create an ENet host host.\n");
        exit (EXIT_FAILURE);
    }

    pthread_t pid;
    if (pthread_create(&pid, NULL, _poll, inst) != 0) {
        fprintf(stderr, "rudpsvr_init error: pthread_create fail.\n");
        return NULL;
    }

    struct queue q;
    memset(&q, 0, sizeof(q));
    pthread_mutex_init(&q.lock, NULL);
    pthread_t pid2;
    //pthread_create(&pid2, NULL, readline_stdin, &q);
    readline_stdin(&q);

    //pthread_join(pid, NULL);


    enet_host_destroy(inst->host);

    atexit (enet_deinitialize);
    return 0;
}

