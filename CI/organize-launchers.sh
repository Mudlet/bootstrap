#!/bin/bash

echo "=== Organizing launchers by game ==="
        
# Create organized structure
mkdir -p organized-releases

# Read GameList.txt and create releases for each game
if [ -f "GameList.txt" ]; then
    while IFS= read -r game || [ -n "$game" ]; do
    # Skip empty lines and comments
    if [[ -n "$game" && ! "$game" =~ ^[[:space:]]*# ]]; then
        echo "Creating release assets for game: $game"
        
        # Find all launchers for this game
        find ./release-artifacts -name "*$game*" -type f | while read launcher; do
        if [ -f "$launcher" ]; then
            filename=$(basename "$launcher")
            echo "  Found: $filename"
            
            # Copy to organized structure
            mkdir -p "organized-releases/$game"
            cp "$launcher" "organized-releases/$game/"
        fi
        done
        
        # Create a README for this game's release
        if [ -d "organized-releases/$game" ]; then
        cat > "organized-releases/$game/README.md" << EOF
# MudletBootstrap - $game

## Installation Instructions

Choose the appropriate file for your platform:

### Windows
- Download \`MudletBootstrap-$game-Windows.exe\`
- Run the executable directly

### macOS
- Download \`MudletBootstrap-$game-macOS.dmg\`
- Open the DMG file and launch the MudletBootstrap app

### Linux
- Download \`MudletBootstrap-$game-Linux.AppImage.tar\`
- Extract the tar file: \`tar -xf MudletBootstrap-$game-Linux.AppImage.tar\`
- Run the AppImage: \`./MudletBootstrap-$game.AppImage\`

## About

This is the MudletBootstrap launcher specifically configured for $game.
EOF
        fi
    fi
    done < GameList.txt
fi

echo "Organized structure:"
find organized-releases -type f | sort
