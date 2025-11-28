#!/bin/bash

echo "=== Organizing launchers by game ==="

echo "Listing files in ./platform-artifacts"
ls ./platform-artifacts

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

# If no extracted-games directories found, look for game files in the artifact directories directly
if [ ! "$(ls -A organized-releases 2>/dev/null)" ]; then
    echo "No extracted-games directories found, looking for game files in artifact directories..."
    
    # Check each platform artifact directory
    for platform_dir in ./platform-artifacts/*/; do
        if [ -d "$platform_dir" ]; then
            platform_name=$(basename "$platform_dir")
            echo "Checking platform directory: $platform_name"
            
            # Look for game launcher files
            case "$platform_name" in
                *MINGW64*|*Windows*)
                    echo "  Looking for Windows executables..."
                    find "$platform_dir" -name "*.exe" -type f | while read launcher; do
                        if [ -f "$launcher" ]; then
                            filename=$(basename "$launcher")
                            echo "  Found Windows launcher: $filename"
                            # Extract game name (format: MudletInstaller-GameName.exe)
                            if [[ "$filename" =~ MudletInstaller-(.+)\.exe$ ]]; then
                                gameName="${BASH_REMATCH[1]}"
                                echo "    Game: $gameName"
                                mkdir -p "organized-releases/$gameName"
                                cp "$launcher" "organized-releases/$gameName/MudletInstaller-$gameName-Windows.exe"
                            fi
                        fi
                    done
                    ;;
                *macOS*)
                    echo "  Looking for macOS DMG files..."
                    find "$platform_dir" -name "*.dmg" -type f | while read launcher; do
                        if [ -f "$launcher" ]; then
                            filename=$(basename "$launcher")
                            echo "  Found macOS launcher: $filename"
                            # Extract game name (format: MudletInstaller-GameName.dmg)
                            if [[ "$filename" =~ MudletInstaller-(.+)\.dmg$ ]]; then
                                gameName="${BASH_REMATCH[1]}"
                                echo "    Game: $gameName"
                                mkdir -p "organized-releases/$gameName"
                                cp "$launcher" "organized-releases/$gameName/MudletInstaller-$gameName-macOS.dmg"
                            fi
                        fi
                    done
                    ;;
                *linux*)
                    echo "  Looking for Linux AppImage files..."
                    find "$platform_dir" -name "*.AppImage.tar" -type f | while read launcher; do
                        if [ -f "$launcher" ]; then
                            filename=$(basename "$launcher")
                            echo "  Found Linux launcher: $filename"
                            # Extract game name (format: MudletInstaller-linux-x64-GameName.AppImage.tar)
                            if [[ "$filename" =~ MudletInstaller-linux-x64-(.+)\.AppImage\.tar$ ]]; then
                                gameName="${BASH_REMATCH[1]}"
                                echo "    Game: $gameName"
                                mkdir -p "organized-releases/$gameName"
                                cp "$launcher" "organized-releases/$gameName/MudletInstaller-$gameName-Linux.AppImage.tar"
                            fi
                        fi
                    done
                    ;;
            esac
        fi
    done
fi

echo "Final organized structure:"
find organized-releases -type f | sort
