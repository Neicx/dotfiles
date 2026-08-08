#!/bin/bash

DEVICE="dll07a6:01-044e:120b"
STATE_FILE="/tmp/touchpad_state"

if [ -f "$STATE_FILE" ]; then
    hyprctl keyword "device[$DEVICE]:enabled" true
    rm "$STATE_FILE"
    notify-send "Touchpad" "Activado"
else
    hyprctl keyword "device[$DEVICE]:enabled" false
    touch "$STATE_FILE"
    notify-send "Touchpad" "Bloqueado"
fi
