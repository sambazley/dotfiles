
FILE="$0"

function rofi_menu {
    prompt=${1-menu}
    columns=${2-20}
    lines=${3-5}

    width=$(( columns * 7 + 12 ))

    output_width="$(xrandr | grep "^$BAR_OUTPUT connected" | sed -E 's/^.*\s([0-9]+)x.*/\1/')"
    output_x="$(xrandr | grep "^$BAR_OUTPUT connected" | sed -E 's/^.*\+([0-9]+)\+.*/\1/')"

    padding="$(bspc config window_gap)"

    rofi_x_min=$(( output_x + padding ))
    rofi_x_max=$(( output_x + output_width - width - padding ))

    rofi_x=$(( BLOCK_X + BLOCK_WIDTH / 2 - width / 2 ))
    rofi_x=$(( rofi_x < rofi_x_min ? rofi_x_min : rofi_x ))
    rofi_x=$(( rofi_x > rofi_x_max ? rofi_x_max : rofi_x ))

    shift 3

#    rofi -modi "$prompt:$FILE rofi" -show "$prompt" -font "Mono 9" \
#        -width "$width" -lines "$lines" \
#        -m primary -location 1 -yoffset 30 -xoffset $rofi_x "$@" \
#        -theme-str '#listview {fixed-height: false;}'

    menu=$("$FILE" rofi)

    while :; do
        [[ "$menu" == "" ]] && break

        row=$( (echo "$menu" | grep -Fn '<%selected%>' || echo '1') | cut -d':' -f1)
        row=$(( row - 1 ))
        menu=$(echo "$menu" | sed 's/<%selected%>//g')

        n=$(echo "$menu" | rofi -dmenu -i -format i -p "$prompt" \
            -font "Mono 9" -width "$width" -lines "$lines" \
            -m primary -location 1 -yoffset 30 -xoffset "$rofi_x" "$@" \
            -selected-row "$row" -theme-str '#listview {fixed-height: false;}')

        [[ "$n" == "" ]] && break

        output=$(echo "$menu" | head -n$(( n + 1 )) | tail -n1)
        menu=$("$FILE" rofi "$output")
    done

}
