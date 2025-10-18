/*
 * #gcc -g -Wall -D__STDC_NO_ATOMICS__ -o testsvr socket_server.c testtcp.c -lpthread
 */
#define _POSIX_C_SOURCE 1L
#include "socket_server.h"
#include "socket_buffer.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#if defined(__MINGW32__) || defined(__MINGW64__)
#include <bits.h>
#endif

static void *
_poll(void * ud) {
	struct socket_server *ss = ud;
	struct socket_message result;
	for (;;) {
		int type = socket_server_poll(ss, &result, NULL);
		// DO NOT use any ctrl command (socket_server_close , etc. ) in this thread.
		switch (type) {
		case SOCKET_EXIT:
			return NULL;
		case SOCKET_DATA:
			printf("message tcp(%lu) from server [id=%d] size=%d data=%s\n",result.opaque,result.id, result.ud, result.data);
			free(result.data);
			break;
        case SOCKET_UDP:
            printf("message udp(%lu) from server [id=%d] size=%d data=%s\n",result.opaque,result.id, result.ud, result.data);
            free(result.data);
            break;
		case SOCKET_CLOSE:
			printf("close(%lu) [id=%d]\n",result.opaque,result.id);
			break;
		case SOCKET_OPEN:
			printf("open(%lu) [id=%d] %s\n",result.opaque,result.id,result.data);
                struct socket_sendbuffer buf;
                buf.id = result.id;
                buf.type = SOCKET_BUFFER_MEMORY;
                char *str = malloc(128);
                memset(str, 0, strlen(str));
                char str2[] = "nihao113hao";
                strncpy(str, str2, strlen(str2));
                buf.buffer = str;
                buf.sz = strlen(str);
                int ret = socket_server_send(ss, &buf);
                if(ret == 0) {
                    fprintf(stdout, "send to server ok, str=\n", (char *)buf.buffer);
                } else {
                    fprintf(stderr, "send to server error\n");
                }
			break;
        case SOCKET_ACCEPT:
            printf("accept(%lu) [id=%d %s] from [%d]\n",result.opaque, result.ud, result.data, result.id);
            break;
		case SOCKET_ERR:
			printf("error(%lu) [id=%d]\n",result.opaque,result.id);
			break;
        case SOCKET_WARNING:
            printf("warning(%lu) [id=%d]\n",result.opaque,result.id);
            break;
		}
	}
}

static void
test(struct socket_server *ss) {
	pthread_t pid;
	pthread_create(&pid, NULL, _poll, ss);

//	int c = socket_server_connect(ss,100,"127.0.0.1",80);
//	printf("connecting %d\n",c);
//	int l = socket_server_listen(ss,200,"127.0.0.1",8888,32);
//	printf("listening %d\n",l);
//	socket_server_start(ss,201,l);
//	int b = socket_server_bind(ss,300,1);//1=stdin
//	printf("binding stdin %d\n",b);

    socket_server_connect(ss, 401, "127.0.0.1", 1234);
	//sleep(5);
	//socket_server_exit(ss);

	pthread_join(pid, NULL);
}

int
main() {
	struct sigaction sa;
	sa.sa_handler = SIG_IGN;
	sigaction(SIGPIPE, &sa, 0);

	struct socket_server * ss = socket_server_create(0);
	test(ss);
	socket_server_release(ss);

	return 0;
}
