socket-server : socket_server.c testtcpsvr.c
	gcc -g -Wall -D__STDC_NO_ATOMICS__ -o $@ $^ -lpthread

clean:
	rm -f *.o *.so socket-server
