#!/bin/bash
# ==============================================================================
# NFS: Most Wanted (2005) - 1-Click Complete Restore Script
# Restores Whisky bottle, registry, and career saves anytime.
# ==============================================================================

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHISKY_BOTTLES="$HOME/Library/Containers/com.franke.Whisky/Bottles"
BOTTLE_UUID="2ED2AE69-D491-46CC-8AF5-AD25236121AE"
TARGET_BOTTLE="$WHISKY_BOTTLES/$BOTTLE_UUID"

echo "=========================================================="
echo "🏎️  NFS Most Wanted (2005) - Restoring Everything"
echo "=========================================================="
echo ""

# 1. Check if Bottle is in Trash and restore it, or extract from archive
if [ -d "$HOME/.Trash/$BOTTLE_UUID" ]; then
    echo "📦 Restoring Whisky Bottle from Trash..."
    mkdir -p "$WHISKY_BOTTLES"
    mv "$HOME/.Trash/$BOTTLE_UUID" "$TARGET_BOTTLE"
    echo "✅ Restored bottle to $TARGET_BOTTLE"
elif [ -f "$BACKUP_DIR/whisky_bottle_config.tar.gz" ]; then
    echo "📦 Recreating Bottle configuration from backup..."
    mkdir -p "$TARGET_BOTTLE"
    tar -xzf "$BACKUP_DIR/whisky_bottle_config.tar.gz" -C "$TARGET_BOTTLE"
    echo "✅ Restored bottle registry and metadata"
else
    echo "⚠️ Bottle backup not found. If using Whisky, create a new bottle named 'NFS Most Wanted'."
fi

# 2. Restore Game Saves to macOS Documents
echo "💾 Restoring Career Saves to Documents..."
mkdir -p "$HOME/Documents/NFS Most Wanted"

# Restore from backup directories
if [ -d "$BACKUP_DIR/udayrec_save" ]; then
    cp -rn "$BACKUP_DIR/udayrec_save/"* "$HOME/Documents/NFS Most Wanted/" 2>/dev/null || true
fi
if [ -d "$BACKUP_DIR/bottle_B410_save" ]; then
    cp -rn "$BACKUP_DIR/bottle_B410_save/"* "$HOME/Documents/NFS Most Wanted/" 2>/dev/null || true
fi

echo "✅ Saves restored to $HOME/Documents/NFS Most Wanted"

# 3. Check for Game Directory & setup Wine symlink
CURRENT_USER="$(whoami)"
if [ -d "$TARGET_BOTTLE/drive_c/users/$CURRENT_USER/Documents" ]; then
    ln -sf "$HOME/Documents/NFS Most Wanted" "$TARGET_BOTTLE/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted" 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo "🎉 Restoration Complete! Everything is back in place."
echo "=========================================================="
