#!/usr/bin/env bash

set -e

bbc setting background "$color0"00
bbc setting background "$color0"00
bbc setting divcolor "$bordercolor"

if ! (bbc list-modules | awk '$1 == "background" {exit 1}'); then
    bbc setting background:color "$color0"
    bbc setting background:bordercolor "$bordercolor"
fi

if ! (bbc list-modules | awk '$1 == "vbar" {exit 1}'); then
    bbc setting vbar:barcolor "$focusedcolor"
fi

make clean -C ~/.config/blockbar/scripts
CFLAGS="-I$OUTPUT_DIR" make -C ~/.config/blockbar/scripts -j`nproc`

for id in $(bbc list | awk '{print $1}'); do
    module="$(bbc property "$id" module)"

    if [[ "$module" =~ ^(subblocks|vbar)$ ]]; then
        bbc exec "$id"
    fi
done

bbc dump > ~/.config/blockbar/config
