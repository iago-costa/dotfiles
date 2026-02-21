#!/bin/bash
# Menu to select Dark/Light theme

OPTIONS="Dark Mode
Light Mode"

SELECTED=$(echo "$OPTIONS" | fuzzel -d -p "Theme: " --width 20 --lines 2 --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini)

if [ "$SELECTED" = "Dark Mode" ]; then
    dms ipc call theme dark
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    notify-send "Mode" "Dark Mode Ativado" -i weather-clear-night-symbolic
elif [ "$SELECTED" = "Light Mode" ]; then
    dms ipc call theme light
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    notify-send "Mode" "Light Mode Ativado" -i weather-clear-symbolic
fi
