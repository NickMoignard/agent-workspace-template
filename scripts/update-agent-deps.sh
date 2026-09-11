#!/usr/bin/env bash
# Update (or install) project dependencies inside every git submodule.
# Auto-detects the package manager per submodule.
#
#   scripts/update-agent-deps.sh                 # update all submodules to latest allowed
#   scripts/update-agent-deps.sh --install        # install deps as locked (used by setup)
#   scripts/update-agent-deps.sh --install <dir>  # only that submodule (used by add-submodule)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="update"
[ "${1:-}" = "--install" ] && { MODE="install"; shift; }
ONLY="${1:-}"   # optional single submodule path to limit to

say() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
skip() { printf '\033[0;90m    - %s\033[0m\n' "$1"; }

if [ -n "$ONLY" ]; then
  paths="$ONLY"
else
  # Iterate submodule paths from .gitmodules.
  paths=$(git config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}' || true)
fi
if [ -z "$paths" ]; then
  echo "No submodules registered yet — nothing to do."
  exit 0
fi

for dir in $paths; do
  [ -d "$dir" ] || { skip "$dir (not checked out — run 'make update-submodules')"; continue; }
  say "$dir"
  (
    cd "$dir"
    if [ -f pnpm-lock.yaml ]; then
      [ "$MODE" = install ] && pnpm install --frozen-lockfile || pnpm update
    elif [ -f yarn.lock ]; then
      [ "$MODE" = install ] && yarn install --frozen-lockfile || yarn upgrade
    elif [ -f package-lock.json ] || [ -f package.json ]; then
      [ "$MODE" = install ] && npm ci 2>/dev/null || npm install || npm update
    elif [ -f poetry.lock ] || { [ -f pyproject.toml ] && command -v poetry >/dev/null 2>&1; }; then
      [ "$MODE" = install ] && poetry install || poetry update
    elif [ -f requirements.txt ]; then
      pip install -r requirements.txt ${MODE:+--upgrade}
    elif [ -f go.mod ]; then
      [ "$MODE" = install ] && go mod download || { go get -u ./... && go mod tidy; }
    elif [ -f Cargo.toml ]; then
      [ "$MODE" = install ] && cargo fetch || cargo update
    else
      echo "    (no recognized package manifest — skipping)"
    fi
  ) || printf '\033[1;33m[!]\033[0m dependency step failed in %s (continuing)\n' "$dir"
done

say "Dependency $MODE complete."
