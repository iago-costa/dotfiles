#!/bin/bash
# Toggle Dark/Light mode via DankMaterialShell

RESULT=$(dms ipc call theme toggle 2>&1)

if [ "$RESULT" = "dark" ]; then
    notify-send -t 2000 "Mode" "Dark Mode Ativado" -i weather-clear-night-symbolic
else
    notify-send -t 2000 "Mode" "Light Mode Ativado" -i weather-clear-symbolic
fi
