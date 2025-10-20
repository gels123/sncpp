TARGET =            aoisvc.so
PREFIX =            /usr/local
CFLAGS =            -O0 -g -ggdb -Wall -pedantic -DDEBUG -std=gnu99
CZSET_CFLAGS =      -fPIC
SKYNET_SRC		=   ../../../skynet/skynet-src
LUA_INCLUDE_DIR =   ../../../skynet/3rd/lua

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -I$(SKYNET_SRC) $(CZSET_CFLAGS)
OBJS =              service_aoisvc.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so *.obj

