#!/usr/bin/env bash

set -e

(
    for i in ${colors[@]}; do
        for c in "$(eval echo "\$$i" | tail -c+2 | sed -E 's/(..)/0x\1 /g')"; do
            echo "$c" | xxd -r
        done
    done

    for i in {1..24}; do
        echo "0xff" | xxd -r
    done
) > "$OUTPUT_DIR/colors.data"
