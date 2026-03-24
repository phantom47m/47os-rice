#!/bin/bash
# 47 Industries - macOS-style Screenshot with float preview
# Usage: screenshot-float.sh [fullscreen|selection]

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILEPATH="$SCREENSHOT_DIR/Screenshot_$TIMESTAMP.png"

MODE="${1:-selection}"

case "$MODE" in
    fullscreen)
        sleep 0.2
        maim "$FILEPATH"
        ;;
    selection)
        maim -s -b 2 -c 0.3,0.5,1.0,0.3 "$FILEPATH"
        ;;
esac

# Exit if screenshot was cancelled
[ ! -f "$FILEPATH" ] && exit 0

# Copy to clipboard
xclip -selection clipboard -t image/png < "$FILEPATH"

# Show macOS-style notification with preview
notify-send "Screenshot Saved" "$FILEPATH" \
    -i "$FILEPATH" \
    -t 5000 \
    -a "47 Screenshot"

# Play capture sound if available
[ -x "$HOME/.local/bin/47sound" ] && 47sound play "$HOME/Documents/47industries/sounds/zoom.wav" 2>/dev/null &
