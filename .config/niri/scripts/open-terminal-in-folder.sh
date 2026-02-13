#!/usr/bin/env bash

# Base directories to search
SEARCH_DIRS="$HOME/GITS $HOME/.config $HOME/Downloads"

# Use fd to find directories, max depth 3 to avoid clutter
# If fd is not found, fallback to find? (Assuming fd is installed per config.nix)
FOLDERS=$(fd . $SEARCH_DIRS --type d --max-depth 3 2>/dev/null)

# Pass to fuzzel, prompting for Terminal
SELECTED=$(echo "$FOLDERS" | fuzzel -d --config /home/zen/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/.config/fuzzel/fuzzel.ini --width 80 --prompt "Terminal in: ")

# If selected, open alacritty in that folder
if [ -n "$SELECTED" ]; then
    # Launch alacritty in the selected directory
    alacritty --working-directory "$SELECTED" &
fi
