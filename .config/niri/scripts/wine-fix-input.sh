#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Wine Input Fix — Force-release keyboard/mouse grabs        ║
# ║  Use: Mod+Escape when Wine steals keyboard on workspace     ║
# ║  switch or when input gets stuck.                           ║
# ╚══════════════════════════════════════════════════════════════╝

# Force XWayland to release all input grabs
if command -v xdotool &>/dev/null; then
    # Release any keyboard/mouse grabs via X11
    xdotool key --clearmodifiers super
fi

# Tell Niri to re-focus the current window (resets input state)
niri msg action focus-column-left
niri msg action focus-column-right

# Notify user
notify-send -t 2000 "🔧 Wine Input Fix" "Keyboard/mouse input released"
