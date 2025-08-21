#!/bin/bash

# Read GameList.txt and create a release for each game
if [ -f "GameList.txt" ]; then
    while IFS= read -r game || [ -n "$game" ]; do
    # Skip empty lines and comments
    if [[ -n "$game" && ! "$game" =~ ^[[:space:]]*# ]]; then
        if [ -d "organized-releases/$game" ]; then
        echo "Creating release for $game..."
        
        # Create release using GitHub CLI (if available) or softprops action
        # For now, we'll use the softprops action approach with multiple calls
        
        # Count files for this game
        file_count=$(find "organized-releases/$game" -name "MudletBootstrap-*" -type f | wc -l)
        
        if [ "$file_count" -gt 0 ]; then
            echo "Found $file_count launcher(s) for $game"
            
            # We'll create a combined release at the end instead of individual releases
            # This is because GitHub Actions doesn't easily support dynamic releases in a loop
        fi
        fi
    fi
    done < GameList.txt
fi