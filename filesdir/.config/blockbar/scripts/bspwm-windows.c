#include "sbtheme.h"
#include "bspc.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <ujson.h>
#include <xcb/xcb.h>
#include <xcb/xcb_ewmh.h>

static char *bar_output;
static int block_button;
static int subblock;

struct Node {
    char *id;
    char *text;
    int urgent;
    xcb_window_t id_numeric;
};

static struct Node *nodes;
static int node_count;

static struct Node *focused_node;

static char focused_desktop [BUFSIZ];

#define SEND(...) bspc_send(__VA_ARGS__, 0)

static int is_monocle() {
    char *rsp = SEND("query", "-T", "-d", focused_desktop);

    if (!rsp) {
        return 0;
    }

    JsonError err;
    jsonErrorInit(&err);

    JsonObject *jo = jsonParseString(rsp, &err);

    free(rsp);

    int err_set = jsonErrorIsSet(&err);
    if (!jo || err_set) {
        if (err_set) {
            jsonErrorCleanup(&err);
        }
        if (jo) {
            jsonCleanup(jo);
        }
        return 0;
    }

    char *layout;
    jsonGetString(jo, "layout", &layout, &err);

    int ret = strcmp(layout, "monocle") == 0;

    jsonCleanup(jo);
    return ret;
}

static int query_node(char *node_id, char *descriptor) {
    char query [BUFSIZ] = {0};
    strcat(query, node_id);
    strcat(query, ".");
    strcat(query, descriptor);

    char *rsp = SEND("query", "-N", "-n", query);

    int ret = rsp != 0;

    if (rsp) {
        free(rsp);
    }

    return ret;
}

static void capitalize(char *str) {
    char lastChar = ' ';
    for (int i = 0; i < strlen(str); i++) {
        if (lastChar == ' ') {
            *str = toupper(*str);
        }
        lastChar = *str;
    }
};

static int get_nodes() {
    struct AtomData {
        char *str;
        xcb_intern_atom_cookie_t cookie;
        xcb_intern_atom_reply_t *reply;
        xcb_atom_t atom;
    } atomData[] = {
        {.str = "WM_CLASS"},
        {.str = "_NET_CLIENT_LIST_STACKING"},
    };
    int atom_count = sizeof(atomData) / sizeof(struct AtomData);

    int err = 0;
    xcb_connection_t *c = xcb_connect(0, 0);

    xcb_screen_t *screen = xcb_setup_roots_iterator(xcb_get_setup(c)).data;
    xcb_window_t root = screen->root;

    for (int i = 0; i < atom_count; i++) {
        struct AtomData *ad = &atomData[i];
        ad->cookie = xcb_intern_atom(c, 0, strlen(ad->str), ad->str);
    }
    for (int i = 0; i < atom_count; i++) {
        struct AtomData *ad = &atomData[i];
        ad->reply = xcb_intern_atom_reply(c, ad->cookie, 0);
        ad->atom = ad->reply->atom;
    }

    char *node_ids = SEND("query", "-d", focused_desktop, "-n", ".window.!floating", "-N");
    char *node_id = node_ids;

    if (!node_ids) {
        err = 1;
        goto end;
    }

    strtok(node_id, "\n");
    while (node_id) {
        nodes = realloc(nodes, sizeof(struct Node) * ++node_count);
        struct Node *node = &nodes[node_count - 1];

        node->id = malloc(strlen(node_id) + 1);
        strcpy(node->id, node_id);

        node->id_numeric = strtol(node_id, 0, 0);

        node->urgent = query_node(node_id, "urgent");

        xcb_get_property_cookie_t wm_class_cookie = xcb_get_property(c, 0, node->id_numeric, atomData[0].atom, XCB_ATOM_STRING, 0, BUFSIZ);
        xcb_get_property_reply_t *wm_class_reply = xcb_get_property_reply(c, wm_class_cookie, 0);
        if (!wm_class_reply) {
            err = 1;
            goto end;
        }

        char *class = xcb_get_property_value(wm_class_reply);
        char *title = class + strlen(class) + 1; //todo somehow check that title is set (ie WM_CLASS doesn't just have one value)
        node->text = malloc(strlen(title) + 1);
        strcpy(node->text, title);
        capitalize(node->text);
        free(wm_class_reply);

        node_id = strtok(NULL, "\n");
    }

    free(node_ids);

    if (node_count <= 1) {
        err = 1;
        goto end;
    }

    xcb_get_property_cookie_t client_list_cookie = xcb_get_property(c, 0, root, atomData[1].atom, XCB_ATOM_WINDOW, 0, BUFSIZ);
    xcb_get_property_reply_t *client_list_reply = xcb_get_property_reply(c, client_list_cookie, 0);
    if (!client_list_reply) {
        err = 1;
        goto end;
    }

    int len = xcb_get_property_value_length(client_list_reply);
    xcb_window_t *val = xcb_get_property_value(client_list_reply);

    for (int i = len / sizeof(xcb_window_t) - 1; i; i--) {
        for (int j = 0; j < node_count; j++) {
            if (val[i] == nodes[j].id_numeric) {
                focused_node = &nodes[j];
                i = 1;
                break;
            }
        }
    }

    free(client_list_reply);

end:
    for (int i = 0; i < atom_count; i++) {
        struct AtomData *ad = &atomData[i];
        free(ad->reply);
    }

    xcb_disconnect(c);

    return !err;
}

static void cleanup() {
    for (int i = 0; i < node_count; i++) {
        free(nodes[i].id);
        free(nodes[i].text);
    }
    free(nodes);
}

#define getintenv(out, name)\
{ \
    char *str = getenv(name); \
    if (str) { \
        out = strtol(str, 0, 0); \
    } \
}
int main(int argc, char *argv[]) {
    bar_output = getenv("BAR_OUTPUT");
    getintenv(block_button, "BLOCK_BUTTON");
    getintenv(subblock, "SUBBLOCK");

    if (!bar_output) {
        return 1;
    }

    strcat(focused_desktop, bar_output);
    strcat(focused_desktop, ":focused");

    if (!is_monocle()) {
        return 1;
    }

    if (!get_nodes()) {
        return 1;
    }

    if (block_button) {
        if (block_button == 1 || block_button == -1) {
            focused_node = &nodes[subblock];
        } else if (block_button == 4) {
            if (focused_node == nodes) {
                focused_node = &nodes[node_count - 1];
            } else {
                focused_node--;
            }
        } else if (block_button == 5) {
            if (focused_node == &nodes[node_count - 1]) {
                focused_node = nodes;
            } else {
                focused_node++;
            }
        }

        char *rsp = SEND("node", "-f", focused_node->id);
        if (rsp) {
            free(rsp);
        }
    }

    printf("{\"subblocks\":[");
    for (int i = 0; i < node_count; i++) {
        struct Node *node = &nodes[i];

        if (i != 0) {
            printf(",");
        }

        printf("{");

        printf("\"text\":\"%s\",", node->text);

        for (int n = 0; n < sizeof(properties) / sizeof(struct Property); n++) {
            struct Property p = properties[n];
            printf("\"%s\":%s,", p.key, p.str);
        }

        #define STR2(x) #x
        #define STR(x) STR2(x)

        if (node->urgent) {
            printf("\"background\":\"" STR(urgentcolor) "\"");
        } else if (node == focused_node) {
            printf("\"background\":\"" STR(focusedcolor) "\"");
        } else {
            printf("\"background\":\"" STR(unfocusedcolor) "\"");
        }

        printf("}");
    }
    printf("]}");

    cleanup();

    return 0;
}
