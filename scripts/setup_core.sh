#!/bin/bash

# scripts/setup_core.sh
# One-time setup for the local Xray-core workspace

CORE_DIR="deps/xray-core"

if [ -d "$CORE_DIR" ]; then
    echo "Core directory already exists. Skipping clone."
else
    mkdir -p deps
    echo "--- Layer 1: Cloning Official Xray (Latest) ---"
    git clone https://github.com/XTLS/Xray-core "$CORE_DIR"
fi

cd "$CORE_DIR"

echo "--- Layer 2: Adding Features Remote (wyx2685) ---"
if git remote | grep -q "features"; then
    echo "Features remote already exists."
else
    git remote add features https://github.com/wyx2685/Xray-core
fi

echo "--- Layer 3: Creating Manual Update Branch ---"
if git branch | grep -q "manual-updates"; then
    echo "Manual update branch already exists."
else
    # Create the branch from the current main
    git checkout -b manual-updates
    echo "Manual update branch created. You can put your custom code here."
    git checkout main
fi

echo "--- Setup Complete ---"
echo "Next steps:"
echo "1. Run './scripts/build_core.sh' to sync and build."
echo "2. Edit code in 'deps/xray-core' on branch 'manual-updates' for your own changes."
