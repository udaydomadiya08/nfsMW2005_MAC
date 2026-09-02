#!/bin/bash
# Quit NFS Most Wanted & cleanly release Wine audio and display devices

for ws in \
    "$HOME/Library/Application Support/com.franke.Whisky/Libraries/Wine/bin/wineserver" \
    "$HOME/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wineserver" \
    "/opt/homebrew/bin/wineserver" \
    "/usr/local/bin/wineserver"; do
    if [ -x "$ws" ]; then
        "$ws" -k 2>/dev/null || true
    fi
done

pkill -9 -f "need for speed" 2>/dev/null || true
pkill -9 -f "speed.exe" 2>/dev/null || true
pkill -9 -f "wine" 2>/dev/null || true
pkill -9 -f "explorer" 2>/dev/null || true
pkill -9 -f "winedevice" 2>/dev/null || true
pkill -9 -f "winedbg" 2>/dev/null || true

echo "Game and Wine processes closed cleanly!"
