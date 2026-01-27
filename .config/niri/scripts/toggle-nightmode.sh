#!/bin/bash
# Toggle night mode via DankMaterialShell (works on all monitors)

RESULT=$(dms ipc call night toggle 2>&1)

if echo "$RESULT" | grep -q "enabled"; then
    notify-send -t 2000 "Night Mode" "Ativado" -i weather-clear-night-symbolic
else
    notify-send -t 2000 "Night Mode" "Desativado" -i display-brightness-symbolic
fi
