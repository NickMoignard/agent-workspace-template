#!/usr/bin/env bash
# Add a project to the workspace as a git submodule and wire it into the
# VS Code workspace. Usage:
#
#     scripts/add-submodule.sh <git-url> [dir] [branch]
#
# Called by `make add-submodule URL=… DIR=… BRANCH=…`.
set -euo pipefail
cd "$(dirname "$0")/.."

URL="${1:-}"
DIR="${2:-}"
BRANCH="${3:-}"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

if [ -z "$URL" ]; then
  echo "Usage: make add-submodule URL=<git-url> [DIR=<folder>] [BRANCH=<branch>]" >&2
  exit 2
fi

# Default DIR to the repo name (strip .git and path).
if [ -z "$DIR" ]; then
  DIR="$(basename "$URL")"; DIR="${DIR%.git}"
fi

if [ -e "$DIR" ]; then
  echo "Refusing to overwrite existing path: $DIR" >&2
  exit 1
fi

say "Adding submodule $URL -> $DIR"
git submodule add ${BRANCH:+-b "$BRANCH"} "$URL" "$DIR"
git submodule update --init --recursive "$DIR"

say "Syncing VS Code workspace folders"
node scripts/sync-workspace.mjs

# Install the new submodule's dependencies using the right package manager.
say "Installing dependencies for $DIR"
bash scripts/update-agent-deps.sh --install "$DIR" || warn "dependency install had issues (continuing)."

# Optionally file a beads issue to onboard the new project.
if command -v bd >/dev/null 2>&1; then
  bd create "Onboard submodule: $DIR" \
    -d "Newly added from $URL. Review its README, wire up CI/build, and confirm it works in the workspace." \
    2>/dev/null && say "Filed a beads onboarding issue for $DIR" || true
fi

cat <<DONE

Added '$DIR'. Don't forget to commit the parent-repo change:
    git add .gitmodules $DIR workspace.code-workspace
    git commit -m "Add $DIR submodule"
DONE
