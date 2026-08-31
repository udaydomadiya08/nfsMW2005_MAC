#!/bin/bash
# NFS Most Wanted - Winetricks Setup
# Installs required Windows components for NFS Most Wanted

set -e

echo "=== NFS Most Wanted - Winetricks Setup ==="
echo ""

# Check if Whisky bottle exists
BOTTLE_PATH="$HOME/Library/Containers/com.isaacmarovitz.Whisky/Bottles/NFS-MostWanted"

if [ ! -d "$BOTTLE_PATH" ]; then
    echo "Error: NFS-MostWanted bottle not found in Whisky"
    echo "Please create the bottle first using Whisky app"
    exit 1
fi

echo "Installing required components via Winetricks..."
echo ""

# Install DirectX 9 runtime (required for NFS Most Wanted)
echo "1. Installing DirectX 9 runtime..."
wine winetricks -q d3dx9

# Install Visual C++ Redistributables
echo "2. Installing Visual C++ Redistributables..."
wine winetricks -q vcrun2005
wine winetricks -q vcrun2008

# Set Windows version to Windows 10
echo "3. Setting Windows version to Windows 10..."
wine winetricks -q win10

# Disable debug output
echo "4. Configuring performance settings..."
wine reg add "HKCU\Software\Wine" /v WINEDEBUG /t REG_SZ /d "-all" /f

echo ""
echo "=== Setup Complete ==="
echo ""
echo "You can now install NFS Most Wanted through Whisky!"
echo "Run the game installer and configure graphics as needed."
