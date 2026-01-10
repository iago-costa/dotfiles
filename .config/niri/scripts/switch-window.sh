#!/usr/bin/env bash

# Get list of windows sorted by workspace, formatted as: 
# "[WS <id>] Title [App] | ID:<id>"
WINDOWS=$(niri msg -j windows | jq -r 'sort_by(.workspace_id) | .[] | "[WS \(.workspace_id)] \(.title) [\(.app_id)] | ID:\(.id)"')

# Pass the list to fuzzel for selection
# -d: dmenu mode
# --prompt "Window: "
SELECTED=$(echo "$WINDOWS" | fuzzel -d --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini --width 80 --prompt "Switch Window: ")

# If a window was selected
if [ -n "$SELECTED" ]; then
    # Extract the ID from the end of the string (after "ID:")
    ID=$(echo "$SELECTED" | awk -F'| ID:' '{print $2}')
    
    # Focus the window
    niri msg action focus-window --id "$ID"
fi
