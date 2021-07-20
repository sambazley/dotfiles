#!/bin/bash

rm -f perms

while true; do
    read -r -p "Delete all files in filesdir? [Y/n] " del
    del=${del,,}

    if [[ "$del" =~ ^(yes|y)$ || -z $del ]]; then
        rm -rf filesdir
        mkdir filesdir
        break
    elif [[ "$del" =~ ^(no|n)$ ]]; then
        break
    else
        continue
    fi
done
