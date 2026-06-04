#!/bin/bash

# scripts/build_core.sh
# Multi-layer sync and build script

CORE_DIR="deps/xray-core"
BINARY_NAME="rcon"

if [ ! -d "$CORE_DIR" ]; then
    echo "Core directory not found. Please run ./scripts/setup_core.sh first."
    exit 1
fi

cd "$CORE_DIR"

echo "=== Layer 1: Syncing with Official Xray (Foundation) ==="
git fetch origin
git checkout main
git reset --hard origin/main # Always start with the absolute latest official

echo "=== Layer 2: Auto-Merging Features (wyx2685 Plugin) ==="
git fetch features
git merge features/main --no-edit
if [ $? -ne 0 ]; then
    echo "!!! MERGE CONFLICT (Features) !!!"
    echo "The latest Xray version is incompatible with the feature fork."
    git merge --abort
    exit 1
fi

echo "=== Layer 3: Merging Manual Updates (Customization) ==="
git merge manual-updates --no-edit
if [ $? -ne 0 ]; then
    echo "!!! MERGE CONFLICT (Manual Updates) !!!"
    echo "Your custom changes conflict with the new core/features code."
    echo "Please resolve conflicts in $CORE_DIR manually, commit to 'manual-updates', and try again."
    # We don't abort here so you can fix it
    exit 1
fi

echo "=== Step 4: Building Rcon Project ==="
cd ../..
# Ensure dependencies are tidy
go mod tidy
go build -o "$BINARY_NAME" main.go

if [ $? -eq 0 ]; then
    echo "SUCCESS: Build complete with latest Xray + Features + Customizations."
else
    echo "ERROR: Project build failed."
    exit 1
fi
