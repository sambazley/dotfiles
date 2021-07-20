#include "bspc.h"
#include <poll.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <xcb/xcb.h>

#define SOCKET_PATH_TPL "/tmp/bspwm%s_%i_%i-socket"

char *bspc_send(char *data, ...) {
    int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);

    if (sockfd < 0) {
        fprintf(stderr, "Failed to open socket\n");
        return 0;
    }

    struct sockaddr_un sock_addr;

    sock_addr.sun_family = AF_UNIX;

    char *host = 0;
    int dn, sn;
    if (xcb_parse_display(NULL, &host, &dn, &sn) != 0) {
        snprintf(sock_addr.sun_path, sizeof(sock_addr.sun_path), SOCKET_PATH_TPL, host, dn, sn);
    }

    if (host) {
        free(host);
    }

    if (connect(sockfd, (struct sockaddr *) &sock_addr, sizeof(sock_addr)) == -1) {
        fprintf(stderr, "Error connecting to socket\n");
        close(sockfd);
        return 0;
    }

    char msg [BUFSIZ];
    va_list ap;
    int len = 0;

    va_start(ap, data);
    while (data) {
        len += snprintf(msg + len, sizeof(msg) - len, "%s%c", data, 0);
        data = va_arg(ap, char *);
    }
    va_end(ap);

    if (send(sockfd, msg, len, 0) == -1) {
        fprintf(stderr, "Failed to send data\n");
        close(sockfd);
        return 0;
    }

    char *ret = 0;
    size_t ret_len;
    char rsp [BUFSIZ];
    int n;

    struct pollfd fds [] = {
        {sockfd, POLLIN, 0},
        {STDOUT_FILENO, POLLHUP, 0},
    };

    while (poll(fds, 2, -1) > 0) {
        if (fds[1].revents & (POLLERR | POLLHUP)) {
            break;
        }
        if (fds[0].revents & POLLIN) {
            if ((n = recv(sockfd, rsp, sizeof(rsp), 0)) > 0) {
                rsp[n] = 0;
                if (rsp[0] == 0x07) {
                    free(ret);
                    ret = 0;
                    fprintf(stderr, "%s", rsp + 1);
                } else {
                    ret_len = ret == 0 ? 0 : strlen(ret);
                    ret = realloc(ret, ret_len + strlen(rsp) + 1);
                    strcpy(ret + ret_len, rsp);
                }
            } else {
                break;
            }
        }
    }

    close(sockfd);
    return ret;
}
