#!/bin/bash
set -e

# Re-exports the manual-updates branch from deps/xray-core as patch files.
# Run this after committing new changes to deps/xray-core manual-updates.
# Then commit the updated scripts/patches/ files to the Rcon repo.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_SRC="$SCRIPT_DIR/../deps/xray-core"
PATCHES_DIR="$SCRIPT_DIR/patches"

BASE=$(cd "$CORE_SRC" && git merge-base main manual-updates)

echo "Exporting patches from manual-updates (base: $BASE) -> $PATCHES_DIR"
rm -f "$PATCHES_DIR"/*.patch
git -C "$CORE_SRC" format-patch "$BASE..manual-updates" --output-directory "$PATCHES_DIR"
echo "Done. Commit the updated scripts/patches/ files to the Rcon repo."
