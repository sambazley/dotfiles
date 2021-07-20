#!/usr/bin/env bash

set -e

function generate {
    echo ":root {"
    echo "    --wallpaper: url(\"$IMG\");"

    for i in ${colors[@]}; do
        eval k="$i"
        eval v="\$$i"
        echo "    --$k: $v;"
    done

    echo "}"
}

generate > "$OUTPUT_DIR/colors.css"
