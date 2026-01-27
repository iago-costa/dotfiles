#!/bin/bash
# Menu to select night mode temperature/intensity

# Options: Label | Value
# Lower K = Warmer (Orange)
# Higher K = Cooler (Blue/White)
OPTIONS="3000K (Very Warm)
3500K (Warm)
4000K (Neutral Warm)
4500K (Neutral)
5000K (Daylight)
6000K (Cool)"

# Show menu using system config
SELECTED=$(echo "$OPTIONS" | fuzzel -d -p "Night Temp: " --width 30 --lines 6 --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini)

if [ -n "$SELECTED" ]; then
    # Extract the number (e.g. 3000)
    TEMP=$(echo "$SELECTED" | awk '{print $1}' | sed 's/K//')
    
    # Apply
    dms ipc call night temperature "$TEMP"
    notify-send "Night Mode" "Temperatura definida para ${TEMP}K" -i weather-clear-night-symbolic
fi
