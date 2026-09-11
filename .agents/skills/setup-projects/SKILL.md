---
name: setup-projects
description: Provision the shared git source directory ($AGENTS_GIT_SRC_DIR) and clone+symlink the projects this workspace references. Ensures the env var is set (written to the shell rc file, marker-guarded, default ~/agents/git_repos), creates the directory, then runs the mechanical sync that clones each repo in projects.yaml and links it into projects/. Use when onboarding a workspace, when projects/ is empty, or when `make setup` reports AGENTS_GIT_SRC_DIR is not set.
---

# Set up this workspace's projects

A Workspace references its Projects as **symlinks**, not git submodules: each
Project is cloned once into a shared machine-level directory
(`$AGENTS_GIT_SRC_DIR`) and symlinked into `projects/`. This keeps the Workspace
independent of the Projects it works on (it pins no commits). See
`docs/adr/0004-projects-as-symlinks-not-submodules.md` and `CONTEXT.md`.

You are an agent running this end-to-end. Inspect state, adapt to the OS/shell,
and debug failures yourself rather than handing them back to the user.

## Steps

### 0. Prerequisites

`yq` and `git` must be present. `yq` is installed by `/setup-homebrew`; if it's
missing, run that first, then continue here.

### 1. Ensure `AGENTS_GIT_SRC_DIR` is set (idempotent, marker-guarded)

This is the single machine-level directory where every workspace's Project
clones live.

```bash
echo "${AGENTS_GIT_SRC_DIR:-<unset>}"
```

- **Already set** → use it as-is.
- **Unset** → pick a value. Offer the user a directory or let them set their
  own; default to `~/agents/git_repos`. Then add this **marker-guarded** block
  once to the shell rc file (`~/.zshrc` for zsh, `~/.bashrc` for bash,
  `~/.config/fish/config.fish` for fish):

  ```sh
  # >>> agents git src — managed by /setup-projects >>>
  export AGENTS_GIT_SRC_DIR="$HOME/agents/git_repos"
  # <<< agents git src — managed by /setup-projects <<<
  ```

  (fish: `set -gx AGENTS_GIT_SRC_DIR $HOME/agents/git_repos`.)

  Check first: `grep -q 'managed by /setup-projects' <rc>` — only write if
  absent. Then **also export it in the current session** so the next steps work:

  ```bash
  export AGENTS_GIT_SRC_DIR="$HOME/agents/git_repos"
  ```

### 2. Ensure the directory exists

```bash
mkdir -p "$AGENTS_GIT_SRC_DIR"
```

Create parents as needed. Confirm it's writable.

### 3. Clone + link the manifest's projects

Run the mechanical sync (clones any missing repo into `$AGENTS_GIT_SRC_DIR`, then
symlinks it into `projects/`), then regenerate the VS Code folder list:

```bash
make sync-projects      # = bash scripts/sync-projects.sh
make sync-workspace     # rescans projects/ into the *.code-workspace folders
```

`projects.yaml` may be empty in a fresh workspace — that's fine; there is simply
nothing to clone yet. Add projects later with `make add-project URL=<git-url>`.

### 4. Verify

```bash
ls -l projects/                 # each entry is a symlink into $AGENTS_GIT_SRC_DIR
git -C "$AGENTS_GIT_SRC_DIR"/* rev-parse --abbrev-ref HEAD 2>/dev/null || true
```

Confirm every symlink resolves and the `folders` list in the `*.code-workspace`
file lists the linked projects. Then hand back to onboarding (`make setup`).

## Rules

- Edit exactly one rc file, guarded by the marker; keep it idempotent. Never
  hardcode a home path — use `$HOME`.
- The symlinks and clones are per-machine and git-ignored — never commit them.
  Only `projects.yaml` and `projects/README.md` are tracked.
- Clones track each remote's default branch. Do not pin commits here; if a user
  wants a specific ref, that's a normal git operation inside the clone.
- On any failure, diagnose and fix in place — you're the agent, not the user.
