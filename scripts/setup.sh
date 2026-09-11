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

# jq/yq are foundational CLI tools the workspace tooling parses config with.
# They install via Homebrew (see /setup-homebrew); check and point the way.
missing_cli=""
command -v jq >/dev/null 2>&1 || missing_cli="jq"
command -v yq >/dev/null 2>&1 || missing_cli="${missing_cli:+$missing_cli }yq"
if [ -n "$missing_cli" ]; then
  warn "Missing CLI tool(s): $missing_cli — REQUIRED (jq parses JSON, yq parses the project manifest)."
  warn "Install with: brew install $missing_cli   (or run /setup-homebrew)."
else
  say "CLI tools detected (jq $(jq --version 2>/dev/null), yq $(yq --version 2>/dev/null | awk '{print $NF}'))."
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

say "Setting up referenced projects…"
# Projects are cloned into $AGENTS_GIT_SRC_DIR and symlinked into projects/.
# Provisioning that env var + directory is agent-layer work (/setup-projects);
# here we run the mechanical clone/link only when it's already set.
if [ -n "${AGENTS_GIT_SRC_DIR:-}" ]; then
  bash "$ROOT/scripts/sync-projects.sh" || warn "project sync had issues; review output above."
else
  warn "AGENTS_GIT_SRC_DIR is not set — projects can't be cloned/linked yet."
  warn "Run the setup prompt with your agent harness (see README.md), e.g.:"
  warn "    claude \"/setup-projects set up the projects source dir and link this workspace's projects\""
  warn "    codex  \"/setup-projects set up the projects source dir and link this workspace's projects\""
fi

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
  # Initialize the local Dolt database WITHOUT letting bd write its own agent
  # files: --skip-agents keeps AGENTS.md/CLAUDE.md/.claude untouched (the
  # canonical beads instructions already live in AGENTS.md). --init-if-missing
  # makes this idempotent. See docs/adr/0003 and the /setup-beads skill.
  BD_NON_INTERACTIVE=1 bd init --skip-agents --skip-hooks --init-if-missing >/dev/null 2>&1 \
    && echo "  beads ready ($(bd --version 2>/dev/null || echo installed))" \
    || warn "beads init had issues; run '/setup-beads' with your agent to fix."
else
  warn "beads ('bd') is not set up — it is REQUIRED for this workspace (issue tracking)."
  warn "Run the setup prompt with your agent harness (see README.md), e.g.:"
  warn "    claude \"/setup-beads install beads and initialize this workspace\""
  warn "    codex  \"/setup-beads install beads and initialize this workspace\""
fi

say "Installing project dependencies…"
"$ROOT/scripts/update-agent-deps.sh" --install || warn "dependency install had issues; review output above."

say "Syncing VS Code workspace folders…"
bash "$ROOT/scripts/run-node.sh" "$ROOT/scripts/sync-workspace.mjs"

cat <<'DONE'

Workspace ready.

Next steps:
  • If Homebrew/asdf weren't detected above, run /setup-homebrew then /setup-asdf
    with your agent (see README).
  • If AGENTS_GIT_SRC_DIR wasn't set above, run /setup-projects to provision it
    and clone+link this workspace's projects.
  • Open the *.code-workspace file in VS Code (it will suggest extensions).
  • Point your agent at AGENTS.md (Claude Code picks it up via CLAUDE.md).
  • Add projects with:  make add-project URL=<git-url>
  • Keep fresh with:    make update-projects  &&  make update-agent-deps
DONE
