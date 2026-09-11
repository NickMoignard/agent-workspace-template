---
name: setup-asdf
description: Install and configure asdf (v0.16+) and the workspace's toolchains for the current machine. Ensures asdf is present, installs/updates the blessed plugins, wires shims onto PATH idempotently, and runs `asdf install` against .tool-versions. Use when onboarding a machine, when `asdf`/a toolchain is missing, or when `make setup` reports asdf is not configured.
---

# Set up asdf for this workspace

asdf is a **hard requirement** for every agent workspace: node, pnpm, python,
uv, go, ruby, and rust are all managed through it. This skill provisions asdf
and the workspace's toolchains on the current machine.

You are an agent running this end-to-end. Inspect state at each step, adapt to
the OS/shell, and debug failures yourself rather than handing them back to the
user. Work through the steps in order; each depends on the previous.

## Blessed plugin set

Every workspace has all of these asdf plugins installed (adding a plugin is
cheap — it just registers where to fetch versions from):

| Tool | asdf plugin name |
| --- | --- |
| Node.js | `nodejs` |
| pnpm | `pnpm` |
| Python | `python` |
| uv | `uv` |
| Go | `golang` |
| Ruby | `ruby` |
| Rust | `rust` |

**python**, **uv**, and **nodejs** are given a *version* (installed) in every
workspace — nodejs because `npx` drives external skill management (see
`docs/adr/0002`). The rest are added as plugins but only installed in a
workspace that pins a version in its `.tool-versions`.

## Steps

### 0. Prerequisite: Homebrew

asdf is installed via Homebrew, which is a hard requirement on the same level as
asdf. If `brew` is missing, run `/setup-homebrew` first, then continue here.

### 1. Ensure asdf v0.16+ is installed

Require the Go-rewrite era (v0.16+); classic shell-based asdf is not supported.

```bash
asdf --version   # expect v0.16.0 or newer
```

- **Missing** → `brew install asdf`.
- **Present but < v0.16** → `brew upgrade asdf`. Do **not** try to make classic
  (git-cloned, shell-sourced) asdf work; if that's what's installed, remove it
  and install via brew.

(Homebrew always ships current asdf, so brew is the single install path.)

Note the data dir: `ASDF_DATA_DIR` (default `~/.asdf`). Shims live in
`$ASDF_DATA_DIR/shims`.

### 2. Ensure all blessed plugins are present and current

For each plugin in the blessed set: add it if missing, update it if present.

```bash
for p in nodejs pnpm python uv golang ruby rust; do
  asdf plugin list | grep -qx "$p" && asdf plugin update "$p" || asdf plugin add "$p"
done
```

Report which were added vs updated. If a plugin add fails (network, missing
build deps), surface the specific error and the fix (e.g. python needs build
dependencies on some Linux distros) rather than silently skipping.

### 3. Wire shims onto PATH (idempotent, marker-guarded)

On v0.16+ there is **no** `asdf.sh` to source. Put `$ASDF_DATA_DIR/shims` on
`PATH` in the user's shell rc, exactly once.

1. Detect the shell and target rc file:
   - `zsh` → `~/.zshrc`
   - `bash` → `~/.bashrc` (also ensure it's sourced from `~/.bash_profile` on
     macOS login shells)
   - `fish` → `~/.config/fish/config.fish` (use `fish_add_path`)
2. Use this **marker** so re-runs are idempotent — if the block already exists,
   leave it (or replace it), never append a duplicate:

   ```sh
   # >>> asdf shims — managed by /setup-asdf >>>
   export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
   export PATH="$ASDF_DATA_DIR/shims:$PATH"
   # <<< asdf shims — managed by /setup-asdf <<<
   ```

   (fish equivalent: `set -gx ASDF_DATA_DIR $HOME/.asdf; fish_add_path $ASDF_DATA_DIR/shims`.)
3. Check first: `grep -q 'managed by /setup-asdf' <rc>` — only write if absent.
4. **Also export for the current session** so the next steps work without a new
   shell:
   ```bash
   export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
   export PATH="$ASDF_DATA_DIR/shims:$PATH"
   ```

### 4. Pin python + uv if missing, then install

The workspace `.tool-versions` should already pin `python`, `uv`, and `nodejs`.
If any is absent, pin the latest stable (skip free-threaded `…t` python builds;
prefer the current nodejs LTS):

```bash
grep -q '^python ' .tool-versions || asdf set python "$(asdf latest python)"
grep -q '^uv '     .tool-versions || asdf set uv "$(asdf latest uv)"
grep -q '^nodejs ' .tool-versions || asdf set nodejs "$(asdf latest nodejs)"
```

Only pin when missing — never bump an existing pin unless the user asks.

Then install everything the workspace declares:

```bash
asdf install        # reads .tool-versions, installs each pinned version
asdf reshim
```

### 5. Verify

```bash
asdf which python && python --version
asdf which uv && uv --version
```

Confirm the shims resolve. If `python`/`uv` aren't found, the PATH step didn't
take effect in this session — re-check step 3. Then hand back to onboarding
(typically: run `make setup` for the mechanical steps).

## Rules

- Never downgrade to classic asdf or source an `asdf.sh` — this is v0.16+ only.
- Edit exactly one rc file, guarded by the marker; keep it idempotent.
- Adding plugins is universal; installing versions is driven solely by
  `.tool-versions`.
- On any failure, diagnose and fix in place — you're the agent, not the user.
