---
name: setup-homebrew
description: Install and configure Homebrew for the current machine. Ensures brew is present, wires `brew shellenv` onto PATH idempotently, and verifies it works. Use when onboarding a machine, when `brew` is missing, or when `make setup` reports Homebrew is not configured. Run this BEFORE /setup-asdf (asdf is installed via brew).
---

# Set up Homebrew for this workspace

Homebrew is a **hard requirement** for every agent workspace, on the same level
as asdf. It is the package manager the workspace uses to install foundational
tooling — including asdf itself — so **run this before `/setup-asdf`**.

You are an agent running this end-to-end. Inspect state, adapt to the OS/shell,
and debug failures yourself rather than handing them back to the user.

## Steps

### 1. Ensure Homebrew is installed

```bash
brew --version   # any recent version is fine
```

If `brew` is missing, install it non-interactively:

```bash
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- macOS also needs the Command Line Tools (`xcode-select --install`); the
  installer prompts if they're absent.
- Linux (incl. WSL) installs to `/home/linuxbrew/.linuxbrew` and needs `build-essential`
  / `procps` / `curl` / `git`; install those with the system package manager first
  if the installer complains.

### 2. Wire `brew shellenv` onto PATH (idempotent, marker-guarded)

Homebrew's location differs by platform — find the installed `brew` and use its
own `shellenv` (don't hardcode paths):

| Platform | brew path |
| --- | --- |
| macOS Apple Silicon | `/opt/homebrew/bin/brew` |
| macOS Intel | `/usr/local/bin/brew` |
| Linux / WSL | `/home/linuxbrew/.linuxbrew/bin/brew` |

1. Detect the shell and target rc file:
   - `zsh` → `~/.zshrc`
   - `bash` → `~/.bashrc` (also ensure it's sourced from `~/.bash_profile` on
     macOS login shells)
   - `fish` → `~/.config/fish/config.fish`
2. Add this **marker-guarded** block once (resolve `BREW` to the real path found
   above):

   ```sh
   # >>> homebrew — managed by /setup-homebrew >>>
   eval "$(<BREW> shellenv)"
   # <<< homebrew — managed by /setup-homebrew <<<
   ```

   (fish: `eval (<BREW> shellenv)`.)
3. Check first: `grep -q 'managed by /setup-homebrew' <rc>` — only write if absent.
4. **Also eval it in the current session** so the next steps (and `/setup-asdf`)
   work without opening a new shell:
   ```bash
   eval "$(<BREW> shellenv)"
   ```

### 3. Verify

```bash
brew --version
brew doctor   # optional; report warnings but don't block on cosmetic ones
```

Confirm `brew` resolves on PATH in the current session, then continue with
`/setup-asdf` (which installs asdf via `brew install asdf`).

## Rules

- Install non-interactively (`NONINTERACTIVE=1`); never leave a prompt hanging.
- Edit exactly one rc file, guarded by the marker; keep it idempotent.
- Don't hardcode brew's path — resolve it from the platform / from `which brew`.
- On failure, diagnose and fix in place — you're the agent, not the user.
