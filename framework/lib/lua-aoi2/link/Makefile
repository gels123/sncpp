TARGET =            aoilink.so
PREFIX =            /usr/local
CFLAGS =            -O0 -g -ggdb -Wall -pedantic -DDEBUG -std=gnu99
CZSET_CFLAGS =      -fPIC
LUA_INCLUDE_DIR =   ../../../skynet/3rd/lua

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              hash_witness.o link-aoi.o lua-aoi-link.o

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

testmain:
	$(CC) -o $@ -g -I./ -L./ -std=gnu99 testmain.c hash_witness.c link-aoi.c

clean:
	rm -f *.o *.so *.obj testmain

