#!/bin/bash

# --- CONFIGURATION ---
HEADSET_SINK="alsa_output.usb-SteelSeries_Arctis_Nova_7X_Gen_2-00.analog-stereo"
SPEAKER_SINK="alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink"

# Target Device
TARGET_VENDOR="1038"
TARGET_PRODUCT="229e"
TARGET_INTERFACE="05"
# ---------------------

echo "🔍 Scanning for Arctis Nova 7X (Interface $TARGET_INTERFACE)..."

HID_DEV=""

# Loop through all hidraw nodes
for dev in /dev/hidraw*; do
    # 1. Get all properties for this device from udev
    # We use -q property --export to get shell-friendly variables
    # We ignore errors in case a device unplugs during the loop
    props=$(udevadm info -n "$dev" -q property --export 2>/dev/null)
    
    # 2. Source the properties to create variables like $ID_VENDOR_ID
    eval "$props"
    
    # 3. Check if it matches our target
    # ID_USB_INTERFACE_NUM is the key property we need
    if [[ "$ID_VENDOR_ID" == "$TARGET_VENDOR" ]] && \
       [[ "$ID_MODEL_ID" == "$TARGET_PRODUCT" ]] && \
       [[ "$ID_USB_INTERFACE_NUM" == "$TARGET_INTERFACE" ]]; then
        HID_DEV="$dev"
        break
    fi
done

if [ -z "$HID_DEV" ]; then
    echo "❌ Device not found! Ensure the dongle is plugged in."
    # List what we did find to help debug
    echo "Debug Info: Found the following interfaces for SteelSeries:"
    udevadm info --export-db | grep -E "ID_VENDOR_ID=1038|ID_USB_INTERFACE_NUM" | grep -B 5 "ID_MODEL_ID=229e"
    exit 1
fi

echo "✅ Found Target: $HID_DEV"
echo "🎧 Monitor Started..."

# 4. Listen to the file
#cat "$HID_DEV" | hexdump -v -e '/1 "%02x "' -e '/64 "\n"' | \
stdbuf -oL cat "$HID_DEV" | stdbuf -oL hexdump -v -e '/1 "%02x "' -e '/64 "\n"' | \
while read -r line; do
    
    # Connected (b9 03)
    if [[ "$line" == "b9 03"* ]]; then
        echo "🟢 Headset Connected."
        pactl set-default-sink "$HEADSET_SINK"
        
    # Disconnected (b9 02)
    elif [[ "$line" == "b9 02"* ]]; then
        echo "🔴 Headset Disconnected."
        pactl set-default-sink "$SPEAKER_SINK"
    fi
    
done
