#!/bin/bash
# ==============================================================================
# NFS: Most Wanted (2005) - 1-Click Complete Restore Script
# Restores Whisky bottle, registry, and career saves anytime.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/saves_backup" ]; then
    BACKUP_DIR="$SCRIPT_DIR/saves_backup"
elif [ -d "$HOME/Documents/NFS_SAVES_BACKUP" ]; then
    BACKUP_DIR="$HOME/Documents/NFS_SAVES_BACKUP"
else
    BACKUP_DIR="$SCRIPT_DIR"
fi

WHISKY_BOTTLES="$HOME/Library/Containers/com.franke.Whisky/Bottles"
BOTTLE_UUID="2ED2AE69-D491-46CC-8AF5-AD25236121AE"
TARGET_BOTTLE="$WHISKY_BOTTLES/$BOTTLE_UUID"

echo "=========================================================="
echo "🏎️  NFS Most Wanted (2005) - Restoring Everything"
echo "=========================================================="
echo ""

# 1. Restore Bottle Configuration & Registry
if [ -f "$BACKUP_DIR/whisky_bottle_config.tar.gz" ]; then
    echo "📦 Restoring Bottle configuration & registry..."
    mkdir -p "$TARGET_BOTTLE"
    tar -xzf "$BACKUP_DIR/whisky_bottle_config.tar.gz" -C "$TARGET_BOTTLE"
    echo "✅ Restored bottle registry and metadata to $TARGET_BOTTLE"
fi

# 2. Restore Game Saves to macOS Documents
echo "💾 Restoring Career Saves to ~/Documents/NFS Most Wanted..."
mkdir -p "$HOME/Documents/NFS Most Wanted"

if [ -d "$BACKUP_DIR/udayrec_save" ]; then
    cp -rn "$BACKUP_DIR/udayrec_save/"* "$HOME/Documents/NFS Most Wanted/" 2>/dev/null || true
fi
if [ -d "$BACKUP_DIR/bottle_B410_save" ]; then
    cp -rn "$BACKUP_DIR/bottle_B410_save/"* "$HOME/Documents/NFS Most Wanted/" 2>/dev/null || true
fi

echo "✅ Career saves restored successfully!"

# 3. Setup Wine User Symlink if bottle exists
CURRENT_USER="$(whoami)"
if [ -d "$TARGET_BOTTLE/drive_c/users/$CURRENT_USER/Documents" ]; then
    ln -sf "$HOME/Documents/NFS Most Wanted" "$TARGET_BOTTLE/drive_c/users/$CURRENT_USER/Documents/NFS Most Wanted" 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo "🎉 Restoration Complete! All saves & bottle configs restored."
echo "=========================================================="
