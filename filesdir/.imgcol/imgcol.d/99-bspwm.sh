#!/usr/bin/env bash

if [[ "$XDG_SESSION_DESKTOP" != "bspwm" ]]; then
    exit
fi

set -e

bspc config active_border_color "$bordercolor"
bspc config focused_border_color "$focusedcolor"
bspc config normal_border_color "$bordercolor"
bspc config presel_feedback_color "$color4"
