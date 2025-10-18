TARGET =            tolua++
PREFIX =            /usr/local
CFLAGS =            -g -O2 -Wall -ansi -pedantic -DNDEBUG -std=gnu99
LUA_INCLUDE_DIR =   ../../../../skynet/3rd/lua

LNX_LDFLAGS = -llua -ltolua++ -ldl -lm -L$(LUA_INCLUDE_DIR) -L../lib
MAC_LDFLAGS = -llua -ltolua++ -ldl -lm -L$(LUA_INCLUDE_DIR) -L../lib

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -I./ -I../lib
OBJS =              tolua.o toluabind.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"

.c.o:
	$(CC) -c -o $@ $(CFLAGS) $(BUILD_CFLAGS) $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS)

clean:
	rm -f *.o *.so *.a tolua++ tolua++_bootstrap
