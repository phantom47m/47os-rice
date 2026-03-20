#!/bin/bash
# 47 Industries - Spotlight Search (macOS-style app launcher)
rofi -show drun \
    -theme "$HOME/.config/rofi/themes/spotlight.rasi" \
    -display-drun "" \
    -drun-display-format "{name}" \
    -show-icons \
    -icon-theme "WhiteSur-dark" \
    -matching fuzzy \
    -sort \
    -sorting-method fzf \
    -scroll-method 0 \
    -no-lazy-grab \
    -steal-focus
