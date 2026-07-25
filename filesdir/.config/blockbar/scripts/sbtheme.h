#ifndef SBTHEME_H
#define SBTHEME_H

/* Frosted-pill chip colours. Fixed, not from the imgcol palette: the
 * frosted look is a neutral translucent overlay, intentionally wallpaper-
 * agnostic, so these don't follow the generated wallpaper colours. */
#define focusedcolor   #ffffff44
#define unfocusedcolor #00000001
#define urgentcolor    #ff453aff
#define unfocusedfg    #c8d8f0aa
#define urgentfg       #ffffffff

#define PROPERTY(k, v) {#k,#v},

struct Property {
    char *key;
    char *str;
} properties [] = {
    PROPERTY(bgypad, 4)
    PROPERTY(margin, 8)
    PROPERTY(borderwidth, 0)
    PROPERTY(bgrad, 11)
#if defined BSPWM_DESKTOPS || defined SWAY_WORKSPACES
    PROPERTY(bgwidth, 23)
#endif
};

#endif /* SBTHEME_H */
