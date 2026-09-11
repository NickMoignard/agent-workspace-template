#!/usr/bin/env bash
# Onboarding: get a freshly-cloned agent workspace ready to use.
# Idempotent — safe to run repeatedly.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

say() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

# Homebrew and asdf are hard requirements, but installing/configuring them is
# agent-layer work (the /setup-homebrew and /setup-asdf skills), not this
# mechanical script. Check and point the way; don't install here. Toolchain-
# dependent steps below degrade gracefully when they're absent.
if command -v brew >/dev/null 2>&1; then
  say "Homebrew detected ($(brew --version 2>/dev/null | head -1))."
else
  warn "Homebrew is not set up — it is REQUIRED for this workspace (installs asdf & foundational tooling)."
  warn "Run the setup prompt with your agent harness (see README.md), e.g.:"
  warn "    claude \"/setup-homebrew set up Homebrew on this machine\""
  warn "    codex  \"/setup-homebrew set up Homebrew on this machine\""
fi

ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
if command -v asdf >/dev/null 2>&1 && [ -d "$ASDF_DATA_DIR/shims" ]; then
  say "asdf detected ($(asdf --version 2>/dev/null))."
else
  warn "asdf is not set up — it is REQUIRED for this workspace (node/pnpm/python/uv/go/ruby/rust)."
  warn "Run the setup prompt with your agent harness (see README.md), e.g.:"
  warn "    claude \"/setup-asdf set up asdf and this workspace's toolchains\""
  warn "    codex  \"/setup-asdf set up asdf and this workspace's toolchains\""
  warn "Continuing with harness-agnostic steps; toolchain-dependent steps may be skipped."
fi

say "Initializing git submodules (recursive)…"
git submodule update --init --recursive

say "Ensuring harness pointers exist…"
# .claude/skills → ../.agents/skills (symlinks don't always survive clone on Windows)
mkdir -p .claude .agents/skills
if [ ! -L .claude/skills ]; then
  rm -rf .claude/skills
  ln -s ../.agents/skills .claude/skills
  echo "  linked .claude/skills -> ../.agents/skills"
fi
# CLAUDE.md must import AGENTS.md
if ! grep -q '@AGENTS.md' CLAUDE.md 2>/dev/null; then
  warn "CLAUDE.md is missing the '@AGENTS.md' pointer — check it."
fi

say "Setting up the beads issue tracker…"
if command -v bd >/dev/null 2>&1; then
  # bd rebuilds its local .db cache from the committed .jsonl on first use.
  bd import 2>/dev/null || bd init 2>/dev/null || true
  echo "  beads ready ($(bd --version 2>/dev/null || echo installed))"
else
  warn "beads ('bd') is not installed. Install it, then run 'make setup' again."
  warn "  see https://github.com/steveyegge/beads"
fi

say "Installing project dependencies in submodules…"
"$ROOT/scripts/update-agent-deps.sh" --install || warn "dependency install had issues; review output above."

say "Syncing VS Code workspace folders…"
node "$ROOT/scripts/sync-workspace.mjs"

cat <<'DONE'

Workspace ready.

Next steps:
  • If Homebrew/asdf weren't detected above, run /setup-homebrew then /setup-asdf
    with your agent (see README).
  • Open the *.code-workspace file in VS Code (it will suggest extensions).
  • Point your agent at AGENTS.md (Claude Code picks it up via CLAUDE.md).
  • Add projects with:  make add-submodule URL=<git-url> DIR=<folder>
  • Keep fresh with:    make update-submodules  &&  make update-agent-deps
DONE
