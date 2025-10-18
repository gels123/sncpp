TARGET =            rudpsvr.so rudpclient.so
PREFIX =            /usr/local
CFLAGS =            -O2 -g -ggdb -Wall -pedantic -DDEBUG -std=gnu99
CZSET_CFLAGS =      -fPIC
SKYNET_SRC		=   ../../skynet/skynet-src
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua


LNX_LDFLAGS = -g -fPIC -shared
MAC_LDFLAGS = -g -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      	-I$(LUA_INCLUDE_DIR) -I$(SKYNET_SRC) $(CZSET_CFLAGS)
OBJS_SVR =              service_rudpsvr.o callbacks.o compress.o host.o list.o packet.o peer.o protocol.o unix.o win32.o
OBJS_CLI =              rudpclient.o callbacks.o compress.o host.o list.o packet.o peer.o protocol.o unix.o win32.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"

.c.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

rudpsvr.so: $(OBJS_SVR)
	$(CC) $(LDFLAGS) -o $@ $(OBJS_SVR)

rudpclient.so: $(OBJS_CLI)
	$(CC) $(LDFLAGS) -o $@ $(OBJS_CLI)

clean:
	rm -f *.o *.so *.obj testserver testclient

