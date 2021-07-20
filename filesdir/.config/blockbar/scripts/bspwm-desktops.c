#include "sbtheme.h"
#include "bspc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *bar_output;
static int block_button;
static int subblock;

struct Desktop {
    char *id;
    char *text;
    int urgent;
    int occupied;
};

static struct Desktop *desktops;
static int desktop_count;

static struct Desktop *focused = 0;

#define SEND(...) bspc_send(__VA_ARGS__, 0)

static int is_occupied(char *desktop_id) {
    char occupied [BUFSIZ] = {0};
    strcat(occupied, desktop_id);
    strcat(occupied, ".occupied");

    char *occupied_rsp = SEND("query", "-D", "-d", occupied);

    int ret = occupied_rsp != 0;

    if (occupied_rsp) {
        free(occupied_rsp);
    }

    return ret;
}

static int query_desktop(char *desktop_id, char *descriptor) {
    char query [BUFSIZ] = {0};
    strcat(query, desktop_id);
    strcat(query, ".");
    strcat(query, descriptor);

    char *rsp = SEND("query", "-D", "-d", query);

    int ret = rsp != 0;

    if (rsp) {
        free(rsp);
    }

    return ret;
}

static int read_desktops() {
    char *desktop_ids = SEND("query", "-D", "-m", bar_output);
    char *desktop_id = desktop_ids;

    if (!desktop_ids) {
        return 1;
    }

    strtok(desktop_id, "\n");
    while (desktop_id) {
        desktops = realloc(desktops, sizeof(struct Desktop) * ++desktop_count);
        struct Desktop *desktop = &desktops[desktop_count - 1];

        desktop->text = SEND("query", "-d", desktop_id, "-D", "--names");
        if (!desktop->text) {
            return 1;
        }
        desktop->text[strlen(desktop->text) - 1] = '\0';

        desktop->occupied = query_desktop(desktop_id, "occupied");
        desktop->urgent = query_desktop(desktop_id, "urgent");

        desktop->id = malloc(strlen(desktop_id) + 1);
        strcpy(desktop->id, desktop_id);

        desktop_id = strtok(NULL, "\n");
    }

    free(desktop_ids);

    return 0;
}

int get_focused() {
    char focused_str [BUFSIZ] = {0};
    strcat(focused_str, bar_output);
    strcat(focused_str, ":focused");

    char *focused_id = SEND("query", "-d", focused_str, "-D");
    if (!focused_id) {
        return 1;
    }

    focused_id[strlen(focused_id) - 1] = '\0';

    for (int i = 0; i < desktop_count; i++) {
        struct Desktop *desktop = &desktops[i];

        if (strcmp(desktop->id, focused_id) == 0) {
            focused = desktop;

            free(focused_id);
            return 0;
        }
    }

    free(focused_id);
    return 1;
}

void cleanup() {
    for (int i = 0; i < desktop_count; i++) {
        free(desktops[i].id);
        free(desktops[i].text);
    }
    free(desktops);
}

static void relative_desktop(char *relative) {
    char query [BUFSIZ] = {0};
    strcat(query, bar_output);
    strcat(query, ":focused#");
    strcat(query, relative);
    strcat(query, ".local");

    char *rsp = SEND("desktop", "-f", query);

    int ret = rsp != 0;

    if (rsp) {
        free(rsp);
    }
}

#define getintenv(out, name)\
{ \
    char *str = getenv(name); \
    if (str) { \
        out = atoi(str); \
    } \
}
int main(int argc, char *argv[]) {
    bar_output = getenv("BAR_OUTPUT");
    getintenv(block_button, "BLOCK_BUTTON");
    getintenv(subblock, "SUBBLOCK");

    if (!bar_output) {
        return 1;
    }

    if (read_desktops()) {
        return 1;
    }

    if (get_focused()) {
        return 1;
    }

    int blk_count = 0;

    if (block_button == 1) {
        for (int i = 0; i < desktop_count; i++) {
            struct Desktop *desktop = &desktops[i];
            if (!desktop->occupied && desktop != focused) {
                continue;
            }

            if (blk_count == subblock) {
                char *rsp = SEND("desktop", desktop->id, "-f");
                if (rsp) {
                    free(rsp);
                }
                focused = desktop;
                break;
            }

            blk_count++;
        }
    } else {
        if (block_button == 4) {
            relative_desktop("prev");
        } else if (block_button == 5) {
            relative_desktop("next");
        }

        if (get_focused()) {
            return 1;
        }
    }

    blk_count = 0;

    printf("{\"subblocks\":[");

    for (int i = 0; i < desktop_count; i++) {
        struct Desktop *desktop = &desktops[i];

        if (!desktop->occupied && desktop != focused) {
            continue;
        }

        if (blk_count != 0) {
            printf(",");
        }

        printf("{");
        printf("\"text\":\"%s\",", desktop->text);

        for (int n = 0; n < sizeof(properties) / sizeof(struct Property); n++) {
            struct Property p = properties[n];
            printf("\"%s\":%s,", p.key, p.str);
        }

        #define STR2(x) #x
        #define STR(x) STR2(x)

        if (desktop == focused) {
            printf("\"background\":\"" STR(focusedcolor) "\"");
        } else if (desktop->urgent) {
            printf("\"background\":\"" STR(urgentcolor) "\"");
        } else {
            printf("\"background\":\"" STR(unfocusedcolor) "\"");
        }
        printf("}");

        blk_count++;
    }

    printf("]}\n");

    return 0;
}
