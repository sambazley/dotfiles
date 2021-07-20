#!/bin/bash

while read -r line; do
    line=$(echo "$line" | sed -E 's/#.*//g') #Remove comments
    line=$(echo "$line" | sed -E 's/^ *| *$//g') #Trim string
    if [[ "$line" == "" ]]; then
        continue
    fi

    echo "$line"

    rsync -aR "$HOME/./$line" filesdir/
done < files

while read -r line; do
    line=$(echo "$line" | sed -E 's/#.*//g') #Remove comments
    line=$(echo "$line" | sed -E 's/^ *| *$//g') #Trim string
    if [[ "$line" == "" ]]; then
        continue
    fi

    echo "Ignoring $line"

    rm -rf "filesdir/$line"
done < ignore

chmod -R 755 filesdir

[ -f perms ] && rm perms

while read -r file; do
    file="${file/filesdir/.}"
    perm="$(stat -c "%a" "$HOME/$file")"

    echo "$perm $file" >> perms
done <<< "$(find filesdir)"

sort perms -k2 -o perms
