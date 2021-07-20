#!/bin/bash

while read line; do
    perm="$(echo "$line" | cut -d' ' -f1)"
    file="$(echo "$line" | cut -d' ' -f2-)"

    chmod "$perm" "filesdir/$file"
done < perms

rsync -Ha "filesdir/" "$HOME/"
