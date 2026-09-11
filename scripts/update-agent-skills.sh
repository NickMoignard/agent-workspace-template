#!/usr/bin/env bash
# Update external agent skills via the skills.sh CLI (`npx skills`).
#
# External skills are installed as editable copies under .agents/skills/ (the
# `universal` agent target) and tracked in skills-lock.json (the source of
# truth, committed). This script refreshes installed skills to their latest
# upstream versions.
#
# To ADD a skill (then commit the result):
#   npx skills@latest add <owner/repo> -a universal          # pick interactively
#   npx skills@latest add <owner/repo> -a universal --all    # take everything
#   npx skills@latest add <owner/repo> -a universal -s <name>
#
# See docs/adr/0002-external-skills-via-skills-cli.md.
set -euo pipefail
cd "$(dirname "$0")/.."

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

if ! command -v npx >/dev/null 2>&1; then
  warn "npx not found — the baseline nodejs toolchain isn't set up."
  warn "Run /setup-asdf with your agent (installs nodejs from .tool-versions), then retry."
  exit 0
fi

if [ ! -f skills-lock.json ]; then
  echo "No skills-lock.json yet — no external skills installed."
  echo "Add some with:  npx skills@latest add <owner/repo> -a universal"
  exit 0
fi

say "Updating external skills to latest (skills.sh)…"
# -p: project scope (this workspace), -y: non-interactive
npx -y skills@latest update -p -y

say "External skills updated. Review & commit changes under .agents/skills/ and skills-lock.json."
