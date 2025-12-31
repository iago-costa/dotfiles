#!/bin/bash
# Swap all workspaces between two monitors in niri
# Simple approach: move workspaces one by one using workspace names

set -e

# Get workspaces and outputs
workspaces_output=$(niri msg workspaces)
output_names=($(echo "$workspaces_output" | grep '^Output "' | sed 's/Output "\([^"]*\)":$/\1/'))

if [ ${#output_names[@]} -lt 2 ]; then
    notify-send "Swap" "Need 2 monitors"
    exit 1
fi

output1="${output_names[0]}"
output2="${output_names[1]}"

# Count workspaces
count1=$(echo "$workspaces_output" | awk -v out="$output1" '
    /^Output "/ { current = (index($0, out) > 0) }
    current && /^[[:space:]]*\*?[[:space:]]*[0-9]+/ { c++ }
    END { print c+0 }
')

count2=$(echo "$workspaces_output" | awk -v out="$output2" '
    /^Output "/ { current = (index($0, out) > 0) }
    current && /^[[:space:]]*\*?[[:space:]]*[0-9]+/ { c++ }
    END { print c+0 }
')

# Name workspaces to track them
# Phase 1: Name all workspaces on output1
for ((i=1; i<=count1; i++)); do
    niri msg action focus-monitor "$output1"
    niri msg action focus-workspace "$i"
    niri msg action set-workspace-name "A$i"
done

# Phase 2: Name all workspaces on output2
for ((i=1; i<=count2; i++)); do
    niri msg action focus-monitor "$output2"
    niri msg action focus-workspace "$i"
    niri msg action set-workspace-name "B$i"
done

# Phase 3: Move all A* workspaces to output2
for ((i=1; i<=count1; i++)); do
    niri msg action focus-workspace "A$i"
    niri msg action move-workspace-to-monitor "$output2"
done

# Phase 4: Move all B* workspaces to output1
for ((i=1; i<=count2; i++)); do
    niri msg action focus-workspace "B$i"
    niri msg action move-workspace-to-monitor "$output1"
done

# Phase 5: Unname workspaces
for ((i=1; i<=count1; i++)); do
    niri msg action focus-workspace "A$i"
    niri msg action unset-workspace-name
done

for ((i=1; i<=count2; i++)); do
    niri msg action focus-workspace "B$i"
    niri msg action unset-workspace-name
done

# Final: Focus first workspace on each
niri msg action focus-monitor "$output1"
niri msg action focus-workspace 1
niri msg action focus-monitor "$output2" 
niri msg action focus-workspace 1

notify-send "Swap" "Done: $output1 ↔ $output2"
