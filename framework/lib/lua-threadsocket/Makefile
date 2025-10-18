TARGET =            threadsocket.so
PREFIX =            /usr/local
CFLAGS =            -O0 -g -ggdb -Wall -pedantic -DDEBUG
CZSET_CFLAGS =      -fPIC 
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNX_LDFLAGS = -shared -lcurl -lpthread
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -lcurl -lpthread

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              queue.o lua-threadsocket.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so

