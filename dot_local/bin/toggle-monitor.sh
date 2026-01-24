#!/usr/bin/env bash

DISPLAY_ONE="DP-4"
DISPLAY_TWO="DP-1"

# Configuration
TARGET_MODE="31"
DISPLAY_ONE_OFFSET="1900,0"
DISPLAY_TWO_OFFSET="0,1152"

# Get status of the second display
TARGET_SCREEN_STATUS=$(kscreen-doctor -o | awk "/Output: .* $DISPLAY_TWO / {getline; print}" | xargs echo)

if [[ "$TARGET_SCREEN_STATUS" == *"enabled"* ]]; then
    # --- DISABLE MODE ---
    # Turn off DP-2, make DP-4 primary, and reset DP-4 to 0,0 (remove the gap)
    kscreen-doctor output.$DISPLAY_TWO.disable \
                   output.$DISPLAY_ONE.primary \
                   output.$DISPLAY_ONE.position.0,0
else
    # --- ENABLE MODE ---
    # Turn on DP-2, set specific mode/offsets, and make it primary
    kscreen-doctor output.$DISPLAY_TWO.enable \
                   output.$DISPLAY_TWO.mode.$TARGET_MODE \
                   output.$DISPLAY_TWO.primary \
                   output.$DISPLAY_ONE.position.$DISPLAY_ONE_OFFSET \
                   output.$DISPLAY_TWO.position.$DISPLAY_TWO_OFFSET
fi
