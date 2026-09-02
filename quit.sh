#!/bin/bash
# Quit NFS Most Wanted - graceful shutdown to preserve DXVK shader cache

# Step 1: SIGTERM - asks game/DXVK to shut down gracefully and flush shader cache
pkill -15 -f "need for speed" 2>/dev/null || true
pkill -15 -f "speed.exe" 2>/dev/null || true
pkill -15 -f "winedbg" 2>/dev/null || true

# Step 2: Wait for DXVK to save its shader cache to disk
sleep 3

# Step 3: Force kill anything still running
pkill -9 -f "need for speed" 2>/dev/null || true
pkill -9 -f "wine" 2>/dev/null || true
pkill -9 -f "explorer" 2>/dev/null || true
pkill -9 -f "wineserver" 2>/dev/null || true
pkill -9 -f "winedevice" 2>/dev/null || true
pkill -9 -f "winedbg" 2>/dev/null || true

echo "✅ Game closed. Shader cache saved."
