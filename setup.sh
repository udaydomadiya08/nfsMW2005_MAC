#!/bin/bash
# ==============================================================================
# Need for Speed: Most Wanted (2005) - 1-Click macOS Apple Silicon Setup
# Compatible with M1, M2, M3, M4 Macs (macOS Ventura, Sonoma, Sequoia+)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================================"
echo "🏎️  NFS: Most Wanted (2005) - Apple Silicon Mac Setup"
echo "========================================================"
echo ""

# 1. Check OS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Error: This setup script is intended for macOS only."
    exit 1
fi

# 2. Check for Whisky
WHISKY_APP="/Applications/Whisky.app"
if [ ! -d "$WHISKY_APP" ]; then
    echo "⚠️ Whisky is not installed in /Applications."
    echo "Installing Whisky via Homebrew..."
    if command -v brew &>/dev/null; then
        brew install --cask whisky
    else
        echo "Please install Whisky manually from https://getwhisky.link/ or install Homebrew first."
        exit 1
    fi
fi

# 3. Locate Whisky Bottle
echo "🔍 Searching for Whisky Bottle..."
BOTTLE_PATH=""
for container in "com.franke.Whisky" "com.isaacmarovitz.Whisky"; do
    if [ -d "$HOME/Library/Containers/$container/Bottles" ]; then
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
    echo "Please open Whisky app, create a Windows 10 bottle, and rerun this script."
    exit 1
fi
echo "✅ Found Bottle: $(basename "$BOTTLE_PATH")"

# 4. Locate Game Directory
echo ""
if [ -n "$1" ] && [ -d "$1" ]; then
    GAME_DIR="$1"
elif [ -d "$HOME/Documents/NFS Most Wanted (EA)" ]; then
    GAME_DIR="$HOME/Documents/NFS Most Wanted (EA)"
elif [ -f "$SCRIPT_DIR/need for speed most wanted.exe" ] || [ -f "$SCRIPT_DIR/speed.exe" ]; then
    GAME_DIR="$SCRIPT_DIR"
else
    echo "Please enter the full path to your NFS Most Wanted game folder:"
    read -r GAME_DIR
fi

if [ ! -d "$GAME_DIR" ]; then
    echo "❌ Error: Game folder '$GAME_DIR' does not exist."
    exit 1
fi
echo "✅ Game Folder: $GAME_DIR"

# 5. Patch 4GB Memory Limit (Large Address Aware)
echo ""
echo "🧠 Patching Game Memory (4GB Large Address Aware to prevent midgame crashes)..."
python3 -c '
import os, glob
game_dir = "'"$GAME_DIR"'"
for path in glob.glob(os.path.join(game_dir, "*.exe")):
    try:
        with open(path, "r+b") as f:
            data = bytearray(f.read())
            if data[:2] != b"MZ": continue
            pe_offset = int.from_bytes(data[0x3C:0x40], "little")
            if pe_offset + 0x18 > len(data) or data[pe_offset:pe_offset+4] != b"PE\x00\x00": continue
            chars_offset = pe_offset + 0x16
            chars = int.from_bytes(data[chars_offset:chars_offset+2], "little")
            if not (chars & 0x0020):
                chars |= 0x0020
                data[chars_offset:chars_offset+2] = chars.to_bytes(2, "little")
                f.seek(0)
                f.write(data)
                print(f"   ✅ Patched 4GB LAA: {os.path.basename(path)}")
    except Exception as e:
        pass
'

# 6. Install Patched Apple Silicon DXVK D3D9 & Config
echo ""
echo "📦 Installing patched DXVK D3D9 (MoltenVK Apple Silicon edition)..."

# Copy to Game Directory
cp "$SCRIPT_DIR/d3d9.dll" "$GAME_DIR/d3d9.dll"
cp "$SCRIPT_DIR/dxvk.conf" "$GAME_DIR/dxvk.conf"

# Copy to Bottle syswow64 & system32
SYSWOW64="$BOTTLE_PATH/dosdevices/c:/windows/syswow64"
SYSTEM32="$BOTTLE_PATH/dosdevices/c:/windows/system32"

if [ -d "$SYSWOW64" ]; then
    cp "$SCRIPT_DIR/d3d9.dll" "$SYSWOW64/d3d9.dll"
    cp "$SCRIPT_DIR/dxvk.conf" "$SYSWOW64/dxvk.conf"
fi
if [ -d "$SYSTEM32" ]; then
    cp "$SCRIPT_DIR/d3d9.dll" "$SYSTEM32/d3d9.dll"
    cp "$SCRIPT_DIR/dxvk.conf" "$SYSTEM32/dxvk.conf"
fi

# 7. Configure Bottle Registry (Native D3D9 + Retina Mode + Bloom Fix + Win10 + Clean Audio)
echo "⚙️  Configuring Wine Registry settings..."
USER_REG="$BOTTLE_PATH/user.reg"
SYSTEM_REG="$BOTTLE_PATH/system.reg"

# Set DLL overrides: d3d9 = native,builtin
if [ -f "$USER_REG" ]; then
    if ! grep -q '"d3d9"' "$USER_REG" 2>/dev/null; then
        sed -i '' '/\[Software\\\\Wine\\\\DllOverrides\]/a\
"d3d9"="native,builtin"
' "$USER_REG" 2>/dev/null || true
    fi
    if ! grep -q '"dinput8"' "$USER_REG" 2>/dev/null; then
        sed -i '' '/\[Software\\\\Wine\\\\DllOverrides\]/a\
"dinput8"="native,builtin"
' "$USER_REG" 2>/dev/null || true
    fi
    if grep -q 'DirectSound' "$USER_REG" 2>/dev/null; then
        sed -i '' '/\[Software\\\\Wine\\\\DirectSound\]/,+4d' "$USER_REG" 2>/dev/null || true
    fi
    # Enforce Windows 10 in bottle registry to prevent WinXP audio struct initialization fault
    sed -i '' 's/"Version"="winxp"/"Version"="win10"/g' "$USER_REG" 2>/dev/null || true
    sed -i '' 's/"Version"="win7"/"Version"="win10"/g' "$USER_REG" 2>/dev/null || true
    sed -i '' 's/"Version"="win8"/"Version"="win10"/g' "$USER_REG" 2>/dev/null || true
fi

# Fix Bloom texture flickering & remove missing winemenubuilder error
if [ -f "$SYSTEM_REG" ]; then
    sed -i '' 's/"g_VisualTreatment"=dword:00000001/"g_VisualTreatment"=dword:00000000/g' "$SYSTEM_REG" 2>/dev/null || true
    sed -i '' '/"winemenubuilder"/d' "$SYSTEM_REG" 2>/dev/null || true
fi

# 8. Link Career Save Directory to macOS Documents
CURRENT_USER="$(whoami)"
mkdir -p "$HOME/Documents/NFS Most Wanted" 2>/dev/null || true
if [ -d "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents" ]; then
    if [ ! -L "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted" ]; then
        if [ -d "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted" ]; then
            cp -rn "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted/"* "$HOME/Documents/NFS Most Wanted/" 2>/dev/null || true
            rm -rf "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted"
        fi
        ln -sf "$HOME/Documents/NFS Most Wanted" "$BOTTLE_PATH/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted"
    fi
fi

# 9. Copy Launch & Quit Command Scripts to Game Folder
echo "📝 Copying launch.command, quit.command, launch.sh, quit.sh to game folder..."

cp "$SCRIPT_DIR/launch.command" "$GAME_DIR/launch.command"
cp "$SCRIPT_DIR/quit.command" "$GAME_DIR/quit.command"
cp "$SCRIPT_DIR/launch.sh" "$GAME_DIR/launch.sh"
cp "$SCRIPT_DIR/quit.sh" "$GAME_DIR/quit.sh"

chmod +x "$GAME_DIR/launch.command"
chmod +x "$GAME_DIR/quit.command"
chmod +x "$GAME_DIR/launch.sh"
chmod +x "$GAME_DIR/quit.sh"
chmod +x "$SCRIPT_DIR/launch.sh"
chmod +x "$SCRIPT_DIR/quit.sh"

echo ""
echo "========================================================"
echo "🎉 Setup Complete! You are ready to play."
echo "========================================================"
echo ""
echo "▶️  To Play:"
echo "   Double-click: '$GAME_DIR/launch.command'"
echo "   Or run in terminal: ./launch.sh"
echo ""
echo "⏹️  To Quit:"
echo "   Double-click: '$GAME_DIR/quit.command'"
echo "   Or run in terminal: ./quit.sh"
echo "========================================================"
