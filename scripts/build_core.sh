#!/bin/bash
set -e

# deps/xray-core is built from three sources, merged in order:
#   Layer 1 — XTLS/Xray-core          (origin remote)
#   Layer 2 — wyx2685/Xray-core       (features remote)
#   Layer 3 — rcon custom patches      (scripts/patches/*.patch)
#
# go.mod replace directive always points to ./deps/xray-core.
# To add a new patch: commit to deps/xray-core manual-updates branch,
# then run scripts/export_patches.sh and commit the new .patch files.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_DIR="$ROOT_DIR/deps/xray-core"
PATCHES_DIR="$SCRIPT_DIR/patches"
BINARY_NAME="rcon"

cd "$CORE_DIR"
git config user.email "rcon-build@local" 2>/dev/null || true
git config user.name  "Rcon Build"       2>/dev/null || true

echo "=== Layer 1: Syncing with Official Xray-core ==="
git fetch origin
git checkout main
git reset --hard origin/main

echo "=== Layer 2: Merging wyx2685 features ==="
git remote add features https://github.com/wyx2685/Xray-core 2>/dev/null || true
git fetch features
git merge -X theirs features/main --no-edit || {
    echo "!!! MERGE FAILED (features/main)"
    git merge --abort; exit 1
}

echo "=== Layer 3: Applying rcon custom patches ==="
for patch in "$PATCHES_DIR"/*.patch; do
    [ -f "$patch" ] || continue
    echo "  applying: $(basename "$patch")"
    git am "$patch" || {
        echo "!!! PATCH FAILED: $patch"
        echo "    Rebase deps/xray-core manual-updates branch then re-run scripts/export_patches.sh"
        git am --abort; exit 1
    }
done

echo "=== Building Rcon ==="
cd "$ROOT_DIR"
GOEXPERIMENT=jsonv2 go build -o "$BINARY_NAME" main.go

echo "SUCCESS: $BINARY_NAME built."
