#!/usr/bin/env bash

set -e

for i in ${colors[@]}; do
    eval echo "$i=\$$i"
done > "$OUTPUT_DIR/colors.sh"
