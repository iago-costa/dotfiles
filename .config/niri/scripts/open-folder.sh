#!/usr/bin/env bash

# Base directories to search
SEARCH_DIRS="$HOME/GITS $HOME/.config $HOME/Downloads"

# Use fd to find directories, max depth 3 to avoid clutter
# If fd is not found, fallback to find? (Assuming fd is installed per config.nix)
FOLDERS=$(fd . $SEARCH_DIRS --type d --max-depth 3 2>/dev/null)

# Pass to fuzzel
SELECTED=$(echo "$FOLDERS" | fuzzel -d --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini --width 80 --prompt "Open Folder: ")

# If selected, open with xdg-open
if [ -n "$SELECTED" ]; then
    xdg-open "$SELECTED"
fi
