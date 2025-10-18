TARGET =            libkcp_fec.so
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -std=c++11 -fpic
CZSET_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNX_LDFLAGS = -shared -lstdc++
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -lstdc++

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJS =              ikcp.o galois.o galois_table.o matrix.o galois_noasm.o  inversion_tree.o reedsolomon.o fec.o sess.o


all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * linux_kcp_test"
	@echo "  * linux_fec_test"

.c.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -o $@ $<

.cpp.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

linux_kcp_test:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"
	$(CC) kcp_test.cpp -I./ -L./ -lkcp_fec -Wl,-rpath='./' -o kcp_test -std=c++11

linux_fec_test: fec_test.o
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"
	
macosx:	
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so

