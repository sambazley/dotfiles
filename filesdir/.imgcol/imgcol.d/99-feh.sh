#!/usr/bin/env bash

set -e

CMD="convert -size 1x1 canvas:'$IMG' png:- | feh --bg-scale -"
eval $CMD

echo "#!/bin/sh" > ~/.fehbgsolid
echo "$CMD" >> ~/.fehbgsolid
chmod +x ~/.fehbgsolid

#feh --bg-center "$IMG"
