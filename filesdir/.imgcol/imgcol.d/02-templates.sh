#!/usr/bin/env bash

set -e

for i in "$DIR"/templates/*; do
    dest="$(eval echo $(head -n1 "$i"))"
    text="$(tail -n+2 "$i")"

    for c in ${colors[@]}; do
        eval key="$c"
        eval val="\$$c"

        text="$(echo "$text" | sed "s/<% $key %>/$val/g")"
    done

    echo "$text" > "$dest"
done
