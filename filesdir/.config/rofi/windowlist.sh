#!/bin/bash

if [ -n "$1" ]; then
    echo "$1"
    echo "$2"
    echo "$3"
fi

idlist=($(xprop -root | grep '_NET_CLIENT_LIST_STACKING(WINDOW)' | cut -d'#' -f2 | xargs | sed "s/, /\n/g"))

menu=""
for id in "${idlist[@]}"; do
    name=$(xdotool getwindowname $id)
    class=$(xprop -id $id | grep WM_CLASS | cut -d',' -f2 | cut -d'"' -f2)

    classlength=${#class}

    if [[ "classlength" -gt "12" ]]; then
        class=$(echo ${class:0:9}...)
    fi

    menu+="$(printf "%12s  %s" "$class" "$name")\n"
done
menu=${menu%\\n}

id=$(echo -e "$menu" | rofi -dmenu -i -format i -p "windows")
if [[ -n "$id" ]]; then
    xdotool windowactivate "${idlist[$id]}"
fi
