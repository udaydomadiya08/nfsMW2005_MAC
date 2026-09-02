#!/bin/bash
# Quit NFS Most Wanted & clean up all Wine processes

pkill -9 -f "need for speed" 2>/dev/null || true
pkill -9 -f "wine" 2>/dev/null || true
pkill -9 -f "explorer" 2>/dev/null || true
pkill -9 -f "wineserver" 2>/dev/null || true
pkill -9 -f "winedevice" 2>/dev/null || true
pkill -9 -f "winedbg" 2>/dev/null || true

echo "Game and Wine processes closed successfully!"
