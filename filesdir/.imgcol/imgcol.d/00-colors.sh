#!/usr/bin/env bash

set -e

#imgcols="$(imgcol "$IMG")"
imgcols="$IMG
#d6150f
#116e88
#c87c62
#52528d
#955e94
#155e81"

#$color8 - $color14
eval "$(echo "$imgcols" | awk 'BEGIN {i=8} {print "color"i++"=\""$0"\""}')"

color0="$(colortool "$(colortool "$color8" v -70%)" s +0%)"
color15="#c0c0c0"

for i in {1..7}; do
    eval color$i="$(eval colortool \$color$(( i + 8 )) v -10%)"
done

bordercolor="$(colortool "$color0" v -30%)"
focusedcolor="$(colortool "$color0" v +200%)"
unfocusedcolor="$(colortool "$color0" v +100%)"

function deg_diff {
    a="$1"
    b="$2"

    bc <<EOF
    define abs(x) {
        if (x < 0) return (-x)
        return (x)
    }
    define diff(x, y) {
        if (abs(x - y) > 180) {
            return (360 - abs(x - y))
        }
        return abs(x - y)
    }
    diff($a, $b)
EOF
}

urgentcolor="#c53535"
if [[ "$(deg_diff "$(colortool "$urgentcolor" h)" "$(colortool "$color0" h)")" -lt 30 ]]; then
    urgentcolor="#4866f3"
fi

colors=$(eval echo "color{0..15} bordercolor focusedcolor unfocusedcolor urgentcolor")
