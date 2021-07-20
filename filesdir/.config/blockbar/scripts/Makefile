LDFLAGS+=-D$(subst -,_,$@) -lxcb

all: bspwm-desktops bspwm-windows

bspwm-desktops: bspwm-desktops.c sbtheme.h bspc.o

bspwm-windows: LDFLAGS+=-lujson
bspwm-windows: bspwm-windows.c sbtheme.h bspc.o

clean:
	rm -f bspwm-windows bspwm-desktops *.o
