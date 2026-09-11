#!/usr/bin/env bash
# Update (or install) project dependencies inside every referenced project.
# Auto-detects the package manager per project (a symlink under projects/).
#
#   scripts/update-agent-deps.sh                  # update all projects to latest allowed
#   scripts/update-agent-deps.sh --install        # install deps as locked (used by setup)
#   scripts/update-agent-deps.sh --install <dir>  # only that project (used by add-project)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="update"
[ "${1:-}" = "--install" ] && { MODE="install"; shift; }
ONLY="${1:-}"   # optional single project path (e.g. projects/<name>) to limit to

say() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
skip() { printf '\033[0;90m    - %s\033[0m\n' "$1"; }

if [ -n "$ONLY" ]; then
  paths="$ONLY"
else
  # Iterate the project symlinks (or dirs) under projects/.
  paths=$(find projects -mindepth 1 -maxdepth 1 \( -type l -o -type d \) 2>/dev/null | sort || true)
fi
if [ -z "$paths" ]; then
  echo "No projects linked yet — nothing to do (see /setup-projects)."
  exit 0
fi

for dir in $paths; do
  [ -d "$dir" ] || { skip "$dir (symlink doesn't resolve — run 'make sync-projects')"; continue; }
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
