# deps/xray-core — Three-Source Architecture

`deps/xray-core` is a git submodule that serves as the **single Go module** used by Rcon
(`go.mod`: `replace github.com/xtls/xray-core => ./deps/xray-core`).

Its working tree is built by merging **three sources** in order:

```
Layer 1  origin/main        https://github.com/XTLS/Xray-core
              ↓ merge
Layer 2  features/main      https://github.com/wyx2685/Xray-core
              ↓ merge
Layer 3  rcon patches       scripts/patches/*.patch  (committed to this repo)
              ↓
         deps/xray-core     ← what go build sees
```

## Layer 1 — Official Xray-core (XTLS)
The upstream base. The submodule remote `origin` tracks this.  
The submodule pointer in the parent repo is pinned to a tested upstream commit.

## Layer 2 — wyx2685 Feature Fork
Adds extensions used by Rcon (e.g. panel API hooks, traffic stats).  
The submodule remote `features` tracks `https://github.com/wyx2685/Xray-core`.

## Layer 3 — Rcon Custom Patches
Rcon-specific changes that are NOT pushed to any external repo:
- AnyTLS protocol support (`proxy/anytls/`, `infra/conf/anytls.go`)
- Toolchain compatibility fixes

Patches are stored as `.patch` files in `scripts/patches/` and committed to the
Rcon repo so they are available everywhere (local dev, CI, new clones).

The corresponding `deps/xray-core` branch `manual-updates` holds the same commits
as a convenience for local development.

## How the merge is performed

**Locally (first setup or after upstream update):**
```bash
./scripts/build_core.sh
```

**In GitHub Actions CI:**  
The workflow step "Merge wyx2685 features + rcon patches into xray-core" does the
same three-layer merge automatically before `go mod download`.

## Adding a new rcon patch

1. Work on `deps/xray-core` `manual-updates` branch and commit your change there.
2. Export the updated patch set:
   ```bash
   ./scripts/export_patches.sh
   ```
3. Commit the regenerated `scripts/patches/*.patch` files to the Rcon repo.
4. Re-run `./scripts/build_core.sh` to apply the new patch to the working tree.

## What NOT to do

- Do NOT commit directly to `deps/xray-core` `main` — it tracks upstream.
- Do NOT push to `https://github.com/XTLS/Xray-core` — this is not a contribution.
- Do NOT change `go.mod replace` to point anywhere other than `./deps/xray-core`.
- Do NOT create a separate `deps/rcon-core` directory — that was a mistake.
