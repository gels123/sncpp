#include "skynet.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

struct aoisvc_t {
};

static struct aoisvc_t * aoisvc_create(void) {
	struct aoisvc_t *inst = skynet_malloc(sizeof(*inst));
    memset(inst, 0, sizeof(*inst));
	return inst;
}

static void aoisvc_release(struct aoisvc_t * inst) {
	skynet_free(inst);
}


static int getnumbercount(uint32_t n) {
    int count = 0;
    while (n != 0) {
        n = n / 10;
        ++count;
    }
    return count;
}

static void callbackmessage(void *ud, uint32_t watcher, uint32_t marker) {
    struct skynet_context *ctx = ud;
    size_t sz = getnumbercount(watcher) + getnumbercount(marker) + strlen("aoicallback") + 2;
    char *msg = skynet_malloc(sz);
    memset(msg, 0, sz);
    sprintf(msg, "aoicallback %d %d", watcher, marker);
    //caoi server的启动在laoi启动之后，handle理论是caoi = laoi + 1
    //如果失败,就需要换方式了
    skynet_send(ctx, 0, skynet_current_handle() - 1, PTYPE_TEXT | PTYPE_TAG_DONTCOPY, 0, (void *)msg, sz);
}

//
static void _parm(char *msg, int sz, int command_sz) {
    while (command_sz < sz) {
        if (msg[command_sz] != ' ')
            break;
        ++command_sz;
    }
    int i;
    for (i = command_sz; i < sz; i++) {
        msg[i - command_sz] = msg[i];
    }
    msg[i - command_sz] = '\0';
}

static void _ctrl(struct skynet_context *ctx, struct aoisvc_t *inst, const void *msg, int sz) {
    char tmp[sz + 1];
    memcpy(tmp, msg, sz);
    tmp[sz] = '\0';
    char *command = tmp;
    int i;
    if (sz == 0)
        return;
    for (i = 0; i < sz; i++) {
        if (command[i] == ' ') {
            break;
        }
    }
    if (memcmp(command, "update", i) == 0) {
        _parm(tmp, sz, i);
        char *text = tmp;
        char *idstr = strsep(&text, " ");
        if (text == NULL) {
            return;
        }
        int id = strtol(idstr, NULL, 10);
        char *mode = strsep(&text, " ");
        if (text == NULL) {
            return;
        }
        float pos[3] = {0};
        char *posstr = strsep(&text, " ");
        if (text == NULL) {
            return;
        }
        pos[0] = strtof(posstr, NULL);
        posstr = strsep(&text, " ");
        if (text == NULL) {
            return;
        }
        pos[1] = strtof(posstr, NULL);
        posstr = strsep(&text, " ");
        pos[2] = strtof(posstr, NULL);

        aoi_update(inst, id, mode, pos);
        return;
    }
    if (memcmp(command, "message", i) == 0)
    {
        aoi_message(inst, callbackmessage, ctx);
        return;
    }
    skynet_error(ctx, "[aoi] Unkown command : %s", command);
}

static int aoisvc_cb(struct skynet_context *context, void *ud, int type, int session, uint32_t source, const void *msg, size_t sz) {
	struct aoisvc_t * inst = ud;
	switch (type) {
        case PTYPE_TEXT:
            _ctrl(context, inst, msg, (int)sz);
            break;
	}
	return 0;
}

static int aoisvc_init(struct aoisvc_t * inst, struct skynet_context *ctx, const char * parm) {
    skynet_callback(ctx, inst, aoisvc_cb);
    return 0;
}
