#!/usr/bin/env bash

set -e

DIR="$(realpath $(dirname "$0"))"
#IMG="$(realpath $1)"
IMG="$1"

OUTPUT_DIR="$DIR/generated"
mkdir -p "$OUTPUT_DIR"

for f in "$DIR/imgcol.d/"*; do
    echo "==> $(basename $f)"
    . "$f"
done
