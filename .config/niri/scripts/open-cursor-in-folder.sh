#!/usr/bin/env bash

# Base directory to search (Home)
SEARCH_DIRS="$HOME"

# Use fd to find directories, excluding noisy folders for speed
# Removed --max-depth to find everything
FOLDERS=$(fd . "$SEARCH_DIRS" --type d --hidden \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    --exclude .local/share \
    --exclude .cargo \
    --exclude .rustup \
    2>/dev/null)

# Pass to fuzzel, prompting for Cursor
SELECTED=$(echo "$FOLDERS" | fuzzel -d --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini --width 80 --prompt "Cursor in: ")

# If selected, launch Cursor
if [ -n "$SELECTED" ]; then
    cursor "$SELECTED" &
fi
