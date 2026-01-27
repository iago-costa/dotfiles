#!/bin/bash
# Adjust night mode temperature (intensity)
# Usage: night-temp.sh [+|-|value]
# +     = increase warmth (lower K, more orange)
# -     = decrease warmth (higher K, less orange)
# value = set specific temperature (2500-6000)

STEP=500
MIN_TEMP=2500
MAX_TEMP=6000

# Get current temperature from DMS settings
CURRENT=$(grep -oP '"nightModeTemperature":\s*\K\d+' ~/.config/DankMaterialShell/settings.json 2>/dev/null || echo 4000)

case "$1" in
    +|warm|warmer)
        # More warm = lower temperature
        NEW_TEMP=$((CURRENT - STEP))
        [ $NEW_TEMP -lt $MIN_TEMP ] && NEW_TEMP=$MIN_TEMP
        ;;
    -|cool|cooler)
        # Less warm = higher temperature
        NEW_TEMP=$((CURRENT + STEP))
        [ $NEW_TEMP -gt $MAX_TEMP ] && NEW_TEMP=$MAX_TEMP
        ;;
    [0-9]*)
        # Direct value
        NEW_TEMP=$1
        [ $NEW_TEMP -lt $MIN_TEMP ] && NEW_TEMP=$MIN_TEMP
        [ $NEW_TEMP -gt $MAX_TEMP ] && NEW_TEMP=$MAX_TEMP
        ;;
    *)
        echo "Usage: $0 [+|-|value]"
        echo "  +     : more warm (orange)"
        echo "  -     : less warm (white)"
        echo "  value : set 2500-6000K"
        exit 1
        ;;
esac

# Apply via DMS
RESULT=$(dms ipc call night temperature "$NEW_TEMP" 2>&1)

# Show notification with visual indicator
PERCENT=$(( (MAX_TEMP - NEW_TEMP) * 100 / (MAX_TEMP - MIN_TEMP) ))
notify-send -t 2000 "Night Mode" "Intensidade: ${PERCENT}% (${NEW_TEMP}K)" -i weather-clear-night-symbolic
