#!/bin/bash

echo "=== Organizing launchers by game ==="
        
# Create organized structure
mkdir -p organized-releases

# Look for extracted-games directories in the downloaded artifacts
echo "Searching for extracted-games directories..."
find ./platform-artifacts -name "extracted-games" -type d | while read extracted_dir; do
    echo "Found extracted-games directory: $extracted_dir"
    if [ -d "$extracted_dir" ]; then
    # Copy all game directories from this platform's extracted-games
    cp -r "$extracted_dir"/* organized-releases/ 2>/dev/null || true
    fi
done

# Also check if artifacts contain the game files directly
echo "Checking for direct game launcher files..."
find ./platform-artifacts -name "MudletBootstrap-*-Windows.exe" -o -name "MudletBootstrap-*-macOS.dmg" -o -name "MudletBootstrap-*-Linux.AppImage.tar" | while read launcher; do
    if [ -f "$launcher" ]; then
    # Extract game name from filename
    filename=$(basename "$launcher")
    # Extract game name between MudletBootstrap- and -Platform
    if [[ "$filename" =~ MudletBootstrap-(.+)-(Windows|macOS|Linux)\.(exe|dmg|AppImage\.tar)$ ]]; then
        gameName="${BASH_REMATCH[1]}"
        echo "Found launcher for game: $gameName - $launcher"
        mkdir -p "organized-releases/$gameName"
        cp "$launcher" "organized-releases/$gameName/"
    fi
    fi
done

echo "Final organized structure:"
find organized-releases -type f | sort
