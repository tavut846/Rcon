# Xray-core Architecture (3-Layer Sync)

This project uses a customized version of Xray-core located in `deps/xray-core`. The core is maintained as a multi-layer composition to combine official stability, community features, and project-specific requirements.

## The Three Layers

The core is built by merging three distinct sources in order:

1.  **Layer 1: Official Foundation (Foundation)**
    *   **Source:** [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
    *   **Purpose:** Provides the base Xray-core functionality and security updates.
    *   **Git Tracking:** Tracked as `origin/main`.

2.  **Layer 2: Community Features (Plugin)**
    *   **Source:** [wyx2685/Xray-core](https://github.com/wyx2685/Xray-core)
    *   **Purpose:** Adds extended features and improvements not found in the official core.
    *   **Git Tracking:** Tracked as `features/main`.

3.  **Layer 3: Manual Updates (Customization)**
    *   **Source:** Local project modifications.
    *   **Purpose:** Contains specific logic required for Rcon integration and custom patches.
    *   **Git Tracking:** Tracked in the local branch `manual-updates`.

## Management Scripts

Maintenance of this multi-layer core is automated via scripts in the `scripts/` directory:

### `scripts/setup_core.sh`
Performs the initial one-time setup:
*   Clones the official Xray-core into `deps/xray-core`.
*   Adds the `features` remote for wyx2685's fork.
*   Creates the local `manual-updates` branch for customizations.

### `scripts/build_core.sh`
The primary synchronization and build tool. It executes the following workflow:
1.  **Foundation Sync:** Resets the local `main` branch to the latest `origin/main`.
2.  **Feature Merge:** Auto-merges `features/main` into the foundation.
3.  **Custom Merge:** Merges the local `manual-updates` branch into the result.
4.  **Project Build:** Compiles the final `rcon` binary using the resulting source.

## Development Workflow

To add custom changes to the Xray-core:
1.  Navigate to `deps/xray-core`.
2.  Switch to the `manual-updates` branch: `git checkout manual-updates`.
3.  Apply your changes and commit them.
4.  Return to the project root and run `./scripts/build_core.sh` to rebuild the project with your changes integrated.

## Dependency Resolution
The project root `go.mod` uses a `replace` directive to ensure all internal imports resolve to this local composed source:
```go
replace github.com/xtls/xray-core => ./deps/xray-core
```
