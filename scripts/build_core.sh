#!/bin/bash
set -e

# deps/xray-core  — git submodule, NEVER committed to; tracks upstream XTLS/Xray-core
#                   manual-updates branch holds local patches (anytls, etc.)
# deps/rcon-core  — gitignored working copy; produced by this script
#                   go.mod replace directive points here

CORE_SRC="$(cd "$(dirname "$0")/.." && pwd)/deps/xray-core"
CORE_BUILD="$(cd "$(dirname "$0")/.." && pwd)/deps/rcon-core"
BINARY_NAME="rcon"

# ── First-run: initialise deps/rcon-core ─────────────────────────────────────
if [ ! -d "$CORE_BUILD/.git" ]; then
    echo "=== First run: creating deps/rcon-core ==="
    git clone "$CORE_SRC" "$CORE_BUILD"
    cd "$CORE_BUILD"
    # Point 'origin' at the real upstream so we can fetch new releases
    git remote set-url origin https://github.com/XTLS/Xray-core
    # Second upstream: wyx2685 feature fork
    git remote add features https://github.com/wyx2685/Xray-core || true
    # Local patches source (manual-updates branch lives here)
    git remote add patches "$CORE_SRC" || true
    cd -
fi

cd "$CORE_BUILD"

echo "=== Layer 1: Syncing with Official Xray-core ==="
git fetch origin
git checkout main
git reset --hard origin/main

echo "=== Layer 2: Merging wyx2685 features ==="
git fetch features
git merge features/main --no-edit || {
    echo "!!! MERGE CONFLICT (features/main) — resolve in deps/rcon-core then re-run"
    git merge --abort
    exit 1
}

echo "=== Layer 3: Applying local patches (manual-updates) ==="
git fetch patches
git merge patches/manual-updates --no-edit || {
    echo "!!! MERGE CONFLICT (manual-updates) — update deps/xray-core manual-updates branch then re-run"
    git merge --abort
    exit 1
}

echo "=== Layer 4: Building Rcon ==="
cd "$(dirname "$0")/.."
GOEXPERIMENT=jsonv2 go build -o "$BINARY_NAME" main.go

echo "SUCCESS: $BINARY_NAME built with Xray + features + rcon patches."
