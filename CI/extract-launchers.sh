#!/bin/bash

# Extract game launchers for release organization
# Usage: extract-launchers.sh <buildname> <upload_filename> <folder_to_upload>

BUILDNAME="$1"
UPLOAD_FILENAME="$2"
FOLDER_TO_UPLOAD="$3"

echo "=== Processing $UPLOAD_FILENAME for game launcher extraction ==="
echo "Build name: $BUILDNAME"
echo "Folder to upload: $FOLDER_TO_UPLOAD"

# Create extraction directory
mkdir -p extracted-games

# Determine platform and extension based on build name
case "$BUILDNAME" in
    "Windows")
        PLATFORM="Windows"
        EXTENSION=".exe"
        ;;
    "macOS")
        PLATFORM="macOS"
        EXTENSION=".dmg"
        ;;
    "Linux")
        PLATFORM="Linux"
        EXTENSION=".AppImage.tar"
        ;;
    *)
        echo "Unknown build name: $BUILDNAME"
        exit 1
        ;;
esac

echo "Platform: $PLATFORM, Extension: $EXTENSION"

# Check if FOLDER_TO_UPLOAD is a directory that contains the files
if [ -d "$FOLDER_TO_UPLOAD" ]; then
    echo "FOLDER_TO_UPLOAD is a directory, looking for zip file inside..."
    
    # Look for the zip file in the upload directory
    ACTUAL_ZIP=$(find "$FOLDER_TO_UPLOAD" -name "*.zip" -type f | head -1)
    
    if [ -n "$ACTUAL_ZIP" ] && [ -f "$ACTUAL_ZIP" ]; then
        echo "Found zip file: $ACTUAL_ZIP"
        
        # Extract the zip file
        echo "Extracting zip file..."
        unzip -q "$ACTUAL_ZIP" -d temp-extract/
        
        echo "Extracted contents:"
        find temp-extract/ -type f | head -10
        
    else
        echo "No zip file found in $FOLDER_TO_UPLOAD, looking for individual game launchers..."
        
        # If no zip file, look for individual game files directly in the structure
        # Check if we have individual build directories or files
        if [ -f "GameList.txt" ]; then
            echo "Reading GameList.txt..."
            while IFS= read -r game || [ -n "$game" ]; do
                # Skip empty lines and comments
                if [[ -n "$game" && ! "$game" =~ ^[[:space:]]*# ]]; then
                    # Trim whitespace
                    game=$(echo "$game" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    
                    if [ -n "$game" ]; then
                        echo "Processing game: '$game'"
                        
                        # Look for game launchers in various possible locations
                        LAUNCHER=""
                        
                        # Check in upload directory first
                        case "$PLATFORM" in
                            "Windows")
                                LAUNCHER=$(find "$FOLDER_TO_UPLOAD" -name "*$game*.exe" -type f | head -1)
                                ;;
                            "macOS")
                                LAUNCHER=$(find "$FOLDER_TO_UPLOAD" -name "*$game*.dmg" -type f | head -1)
                                ;;
                            "Linux")
                                LAUNCHER=$(find "$FOLDER_TO_UPLOAD" -name "*$game*.AppImage.tar" -type f | head -1)
                                if [ -z "$LAUNCHER" ]; then
                                    # Also try looking for just .AppImage files
                                    LAUNCHER=$(find "$FOLDER_TO_UPLOAD" -name "*$game*.AppImage" -type f | head -1)
                                fi
                                ;;
                        esac
                        
                        # If not found in upload directory, check build directories
                        if [ -z "$LAUNCHER" ]; then
                            case "$PLATFORM" in
                                "Windows")
                                    LAUNCHER=$(find . -path "./build-$game/*" -name "*.exe" -type f | head -1)
                                    ;;
                                "macOS")
                                    LAUNCHER=$(find . -path "./build-$game/*" -name "*.dmg" -type f | head -1)
                                    ;;
                                "Linux")
                                    LAUNCHER=$(find . -path "./build-$game/*" -name "*.AppImage.tar" -type f | head -1)
                                    if [ -z "$LAUNCHER" ]; then
                                        LAUNCHER=$(find . -path "./build-$game/*" -name "*.AppImage" -type f | head -1)
                                    fi
                                    ;;
                            esac
                        fi
                        
                        # If still not found, try current directory
                        if [ -z "$LAUNCHER" ]; then
                            case "$PLATFORM" in
                                "Windows")
                                    LAUNCHER=$(find . -maxdepth 1 -name "*$game*.exe" -type f | head -1)
                                    ;;
                                "macOS")
                                    LAUNCHER=$(find . -maxdepth 1 -name "*$game*.dmg" -type f | head -1)
                                    ;;
                                "Linux")
                                    LAUNCHER=$(find . -maxdepth 1 -name "*$game*.AppImage.tar" -type f | head -1)
                                    if [ -z "$LAUNCHER" ]; then
                                        LAUNCHER=$(find . -maxdepth 1 -name "*$game*.AppImage" -type f | head -1)
                                    fi
                                    ;;
                            esac
                        fi
                        
                        if [ -n "$LAUNCHER" ] && [ -f "$LAUNCHER" ]; then
                            echo "  Found launcher: $LAUNCHER"
                            
                            # Create game directory and copy launcher
                            mkdir -p "extracted-games/$game"
                            
                            # Determine the file extension of the found launcher
                            FOUND_EXT=""
                            if [[ "$LAUNCHER" == *.exe ]]; then
                                FOUND_EXT=".exe"
                            elif [[ "$LAUNCHER" == *.dmg ]]; then
                                FOUND_EXT=".dmg"
                            elif [[ "$LAUNCHER" == *.AppImage.tar ]]; then
                                FOUND_EXT=".AppImage.tar"
                            elif [[ "$LAUNCHER" == *.AppImage ]]; then
                                FOUND_EXT=".AppImage"
                            fi
                            
                            # Copy with standardized filename
                            case "$PLATFORM" in
                                "Windows")
                                    cp "$LAUNCHER" "extracted-games/$game/MudletBootstrap-$game-Windows.exe"
                                    echo "  Copied to: extracted-games/$game/MudletBootstrap-$game-Windows.exe"
                                    ;;
                                "macOS")
                                    cp "$LAUNCHER" "extracted-games/$game/MudletBootstrap-$game-macOS.dmg"
                                    echo "  Copied to: extracted-games/$game/MudletBootstrap-$game-macOS.dmg"
                                    ;;
                                "Linux")
                                    if [[ "$FOUND_EXT" == ".AppImage.tar" ]]; then
                                        cp "$LAUNCHER" "extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar"
                                        echo "  Copied to: extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar"
                                    else
                                        # If it's just .AppImage, create a tar for consistency
                                        tar -cf "extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar" -C "$(dirname "$LAUNCHER")" "$(basename "$LAUNCHER")"
                                        echo "  Packed to: extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar"
                                    fi
                                    ;;
                            esac
                        else
                            echo "  Warning: No launcher found for '$game' on $PLATFORM"
                            echo "  Searched in:"
                            echo "    - $FOLDER_TO_UPLOAD"
                            echo "    - ./build-$game/"
                            echo "    - current directory"
                        fi
                    fi
                fi
            done < GameList.txt
        else
            echo "Error: GameList.txt not found in repository root"
        fi
    fi
elif [ -f "$FOLDER_TO_UPLOAD" ]; then
    echo "FOLDER_TO_UPLOAD is a file, treating as zip..."
    ACTUAL_ZIP="$FOLDER_TO_UPLOAD"
    
    # Extract and process as before
    unzip -q "$ACTUAL_ZIP" -d temp-extract/
    # ... (rest of zip processing logic)
else
    echo "Error: FOLDER_TO_UPLOAD does not exist or is not accessible"
    echo "Path: $FOLDER_TO_UPLOAD"
fi

# Clean up temp extraction if it exists
if [ -d "temp-extract" ]; then
    rm -rf temp-extract/
fi

echo "=== Extraction complete. Results: ==="
if [ -d "extracted-games" ]; then
    find extracted-games/ -type f | sort
else
    echo "No extracted-games directory created"
fi