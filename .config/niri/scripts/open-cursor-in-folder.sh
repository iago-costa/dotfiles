#!/usr/bin/env bash

# Base directories to search
SEARCH_DIRS="$HOME/GITS $HOME/.config $HOME/Downloads"

# Use fd to find directories, max depth 3 to avoid clutter
FOLDERS=$(fd . $SEARCH_DIRS --type d --max-depth 3 2>/dev/null)

# Pass to fuzzel, prompting for Cursor
SELECTED=$(echo "$FOLDERS" | fuzzel -d --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini --width 80 --prompt "Cursor in: ")

# If selected, launch Cursor
if [ -n "$SELECTED" ]; then
    cursor "$SELECTED" &
fi
