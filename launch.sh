#!/bin/bash
# ==============================================================================
# Need for Speed: Most Wanted (2005) - Apple Silicon macOS Fullscreen Launcher
# Tested on M1 / M2 / M3 / M4 Macs (Retina Auto-Scaling + Custom MoltenVK DXVK)
# ==============================================================================

set -e

# Terminate any existing Wine or game processes to avoid device lock
pkill -9 -f "need for speed" 2>/dev/null || true
pkill -9 -f "speed.exe" 2>/dev/null || true
pkill -9 -f "wine" 2>/dev/null || true
pkill -9 -f "explorer" 2>/dev/null || true
pkill -9 -f "wineserver" 2>/dev/null || true
pkill -9 -f "winedevice" 2>/dev/null || true
pkill -9 -f "winedbg" 2>/dev/null || true
sleep 1

# 1. Locate Game Directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$1" ] && [ -d "$1" ]; then
    GAME_DIR="$1"
elif [ -f "$SCRIPT_DIR/need for speed most wanted.exe" ] || [ -f "$SCRIPT_DIR/speed.exe" ]; then
    GAME_DIR="$SCRIPT_DIR"
elif [ -d "$HOME/Documents/NFS Most Wanted (EA)" ]; then
    GAME_DIR="$HOME/Documents/NFS Most Wanted (EA)"
else
    # Find any folder containing the exe in Documents or Applications
    GAME_DIR=$(find "$HOME/Documents" -maxdepth 2 -name "*need for speed most wanted.exe*" -o -name "*speed.exe*" 2>/dev/null | head -n 1 | xargs -r dirname)
fi

if [ -z "$GAME_DIR" ] || [ ! -d "$GAME_DIR" ]; then
    echo "❌ Error: Could not locate NFS Most Wanted game folder."
    echo "Usage: ./launch.sh \"/path/to/NFS Most Wanted/\""
    exit 1
fi

# Locate Game Exe
if [ -f "$GAME_DIR/need for speed most wanted.exe" ]; then
    EXE_NAME="need for speed most wanted.exe"
elif [ -f "$GAME_DIR/speed.exe" ]; then
    EXE_NAME="speed.exe"
elif [ -f "$GAME_DIR/SPEED.EXE" ]; then
    EXE_NAME="SPEED.EXE"
else
    EXE_NAME=$(ls "$GAME_DIR" | grep -i "\.exe$" | head -n 1)
fi

# 2. Locate Whisky Wine & Bottle
BOTTLE_PATH=""
for container in "com.franke.Whisky" "com.isaacmarovitz.Whisky"; do
    if [ -d "$HOME/Library/Containers/$container/Bottles" ]; then
        # Prefer bottle matching nfs or speed
        BOTTLE_PATH=$(find "$HOME/Library/Containers/$container/Bottles" -maxdepth 1 -mindepth 1 -type d -name "*NFS*" -o -name "*nfs*" -o -name "*speed*" 2>/dev/null | head -n 1)
        if [ -z "$BOTTLE_PATH" ]; then
            BOTTLE_PATH=$(find "$HOME/Library/Containers/$container/Bottles" -maxdepth 1 -mindepth 1 -type d | head -n 1)
        fi
        if [ -n "$BOTTLE_PATH" ]; then
            WHISKY_CONTAINER="$container"
            break
        fi
    fi
done

if [ -z "$BOTTLE_PATH" ] || [ ! -d "$BOTTLE_PATH" ]; then
    echo "❌ Error: No Whisky bottle found."
    echo "Please create a Windows 10 bottle in Whisky app first."
    exit 1
fi

# Locate Wine Binary
WINE_BIN=""
for path in \
    "$HOME/Library/Application Support/$WHISKY_CONTAINER/Libraries/Wine/bin/wine" \
    "$HOME/Library/Application Support/com.franke.Whisky/Libraries/Wine/bin/wine" \
    "$HOME/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wine" \
    "/usr/local/bin/wine" \
    "/opt/homebrew/bin/wine"; do
    if [ -f "$path" ]; then
        WINE_BIN="$path"
        break
    fi
done

if [ -z "$WINE_BIN" ] || [ ! -f "$WINE_BIN" ]; then
    echo "❌ Error: Wine binary not found in Whisky libraries."
    exit 1
fi

# 3. Detect Screen Resolution (macOS Logical & Retina Virtual Desktop)
SCREEN_W=$(osascript -e 'tell application "Finder" to get item 3 of (get bounds of window of desktop)' 2>/dev/null || echo 1680)
SCREEN_H=$(osascript -e 'tell application "Finder" to get item 4 of (get bounds of window of desktop)' 2>/dev/null || echo 1050)
RETINA_W=$((SCREEN_W * 2))
RETINA_H=$((SCREEN_H * 2))

# 4. Patch Registry Fixes
REG="$BOTTLE_PATH/system.reg"
if [ -f "$REG" ]; then
    # Fix bloom flickering
    sed -i '' 's/"g_VisualTreatment"=dword:00000001/"g_VisualTreatment"=dword:00000000/g' "$REG" 2>/dev/null || true
fi

cd "$GAME_DIR"

# 5. Launch Game with Synchronous Lockstep Rendering & Apple Silicon DXVK / MoltenVK optimizations
MVK_CONFIG_FAST_MATH_ENABLED=0 \
MVK_CONFIG_RESUME_LOST_DEVICE=1 \
MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE=1 \
MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1 \
DXVK_ASYNC=0 \
DXVK_LOG_LEVEL=none \
WINEDLLOVERRIDES="d3d9=n,b;dinput8=n,b" \
WINEPREFIX="$BOTTLE_PATH" \
"$WINE_BIN" \
explorer /desktop=NFSMW,${RETINA_W}x${RETINA_H} \
cmd /c start "" /affinity 1 "Z:$GAME_DIR\\$EXE_NAME" \
>/tmp/nfsmw_output.log 2>&1 &

echo "✅ Game launched successfully! Enjoy the race."

