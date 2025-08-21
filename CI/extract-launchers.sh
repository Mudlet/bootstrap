echo "=== Processing ${UPLOAD_FILENAME} for game launcher extraction ==="
        
BUILDNAME="$1"
UPLOAD_FILENAME="$2"
FOLDER_TO_UPLOAD="$3"

echo "Processing $UPLOAD_FILENAME for game launcher extraction"
echo "Build name: $BUILDNAME"
echo "Folder to upload: $FOLDER_TO_UPLOAD"

# Create extraction directory
mkdir -p extracted-games

# Determine platform and extension based on build name or runner OS
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
esac

echo "Platform: $PLATFORM, Extension: $EXTENSION"

ACTUAL_ZIP=""

if [ -d "$FOLDER_TO_UPLOAD" ]; then
    # If FOLDER_TO_UPLOAD is a directory, find the zip file in it
    ACTUAL_ZIP=$(find "$FOLDER_TO_UPLOAD" -name "*.zip" -type f | head -1)
elif [ -f "$FOLDER_TO_UPLOAD" ]; then
    # If it's already a file
    ACTUAL_ZIP="$FOLDER_TO_UPLOAD"
fi

# If still not found, try to find by pattern
if [ -z "$ACTUAL_ZIP" ] || [ ! -f "$ACTUAL_ZIP" ]; then
    ACTUAL_ZIP=$(find . -name "MudletBootstrap-*$BUILDNAME*.zip" -o -name "MudletBootstrap-*$PLATFORM*.zip" | head -1)
fi

# Try common patterns based on your naming convention
if [ -z "$ACTUAL_ZIP" ] || [ ! -f "$ACTUAL_ZIP" ]; then
    case "$PLATFORM" in
        "Windows")
            ACTUAL_ZIP=$(find . -name "MudletBootstrap-MINGW64.zip" | head -1)
            ;;
        "macOS")
            ACTUAL_ZIP=$(find . -name "MudletBootstrap-macOS.zip" | head -1)
            ;;
        "Linux")
            ACTUAL_ZIP=$(find . -name "MudletBootstrap-linux-x64.zip" | head -1)
            ;;
    esac
fi

echo "Using zip file: $ACTUAL_ZIP"

if [ -f "$ACTUAL_ZIP" ]; then
    echo "Found zip file, extracting..."
    
    # Extract the zip file
    unzip -q "$ACTUAL_ZIP" -d temp-extract/
    
    echo "Extracted contents:"
    find temp-extract/ -type f | head -10  # Show first 10 files for debugging
    
    # Read the game list
    if [ -f "GameList.txt" ]; then
        echo "Reading GameList.txt..."
        while IFS= read -r game || [ -n "$game" ]; do
            # Skip empty lines and comments
            if [[ -n "$game" && ! "$game" =~ ^[[:space:]]*# ]]; then
                # Trim whitespace
                game=$(echo "$game" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                if [ -n "$game" ]; then
                    echo "Processing game: '$game'"
                    
                    # Look for the game launcher in the extracted files
                    LAUNCHER=""
                    case "$PLATFORM" in
                        "Windows")
                            LAUNCHER=$(find temp-extract/ -name "*$game*.exe" -type f | head -1)
                            ;;
                        "macOS")
                            LAUNCHER=$(find temp-extract/ -name "*$game*.dmg" -type f | head -1)
                            ;;
                        "Linux")
                            LAUNCHER=$(find temp-extract/ -name "*$game*.AppImage.tar" -type f | head -1)
                            ;;
                    esac
                    
                    if [ -n "$LAUNCHER" ] && [ -f "$LAUNCHER" ]; then
                        echo "  Found launcher: $LAUNCHER"
                        
                        # Create game directory and copy launcher
                        mkdir -p "extracted-games/$game"
                        
                        # Standardize the filename
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
                                cp "$LAUNCHER" "extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar"
                                echo "  Copied to: extracted-games/$game/MudletBootstrap-$game-Linux.AppImage.tar"
                                ;;
                        esac
                    else
                        echo "  Warning: No launcher found for '$game' on $PLATFORM"
                        echo "  Looking for pattern: *$game*$EXTENSION"
                        echo "  Available files matching game name:"
                        find temp-extract/ -name "*$game*" -type f | head -5
                    fi
                fi
            fi
        done < GameList.txt
    else
        echo "Error: GameList.txt not found in repository root"
        echo "Current directory contents:"
        ls -la
    fi
    
    # Clean up
    rm -rf temp-extract/
    
    echo "Extraction complete. Results:"
    find extracted-games/ -type f | sort
else
    echo "Error: Could not find zip file to extract"
    echo "Searched for:"
    echo "  - $FOLDER_TO_UPLOAD (as file or directory)"
    echo "  - MudletBootstrap-*$BUILDNAME*.zip"
    echo "  - MudletBootstrap-*$PLATFORM*.zip"
    echo "Current directory contents:"
    ls -la
fi
