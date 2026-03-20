#!/bin/bash
# 47 Industries - Force Quit (macOS Cmd+Option+Esc equivalent)
# Shows a rofi list of running windows, select one to kill it

SELECTED=$(wmctrl -l | awk '{$2=$3=""; print}' | sed 's/^  *//' | \
    rofi -dmenu -p "Force Quit" \
    -theme "$HOME/.config/rofi/themes/spotlight.rasi" \
    -i -matching fuzzy)

[ -z "$SELECTED" ] && exit 0

# Extract window ID (first field from wmctrl output)
WID=$(wmctrl -l | grep -F "$SELECTED" | head -1 | awk '{print $1}')
[ -z "$WID" ] && exit 0

# Try graceful close first, then force kill
xdotool windowclose "$WID" 2>/dev/null || \
    xdotool windowkill "$WID" 2>/dev/null

notify-send "Force Quit" "Application closed" -i process-stop-symbolic -t 2000
