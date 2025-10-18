TARGET =            snapshot.so
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -DUSE_MEM_HOOK -g -std=gnu99
CADD_CFLAGS =       -fPIC 
# LUA_INCLUDE_DIR =   $(/usr/local)/include
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CADD_CFLAGS)
OBJS =              snapshot.o

.PHONY : all linux macosx mingw clean

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
	rm -f *.o *.so