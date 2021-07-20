#!/usr/bin/env bash

set -e

for i in ${colors[@]}; do
    eval k="$i"
    eval v="\$$i"
    echo "#define $k $v"
done > "$OUTPUT_DIR/colors.h"
