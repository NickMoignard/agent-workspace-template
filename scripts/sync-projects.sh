#!/usr/bin/env bash
# Realize projects.yaml into clones + symlinks (the deterministic, mechanical
# half of the projects model; see docs/adr/0004).
#
# For each clone URL in projects.yaml:
#   1. clone it into $AGENTS_GIT_SRC_DIR/<name> if it isn't there yet,
#   2. (re)create projects/<name> -> $AGENTS_GIT_SRC_DIR/<name>.
#
# Idempotent — safe to run repeatedly. Provisioning AGENTS_GIT_SRC_DIR (the env
# var + the directory) is the /setup-projects skill's job; this script only
# reads it. Needs `yq` (parse) and `git`.
set -euo pipefail
cd "$(dirname "$0")/.."

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

# "yq" is ambiguous: mikefarah/yq (Go, what Homebrew installs) vs python-yq
# (the apt/pip `yq`, a jq wrapper with different syntax). We need mikefarah/yq.
require_mikefarah_yq() {
  command -v yq >/dev/null 2>&1 || { warn "yq not found — run /setup-homebrew."; exit 1; }
  if ! yq --version 2>&1 | grep -qi mikefarah; then
    warn "The 'yq' on PATH is not mikefarah/yq (found: $(yq --version 2>&1 | head -1))."
    warn "Install it with 'brew install yq' and ensure Homebrew's bin precedes"
    warn "/usr/bin on PATH (see /setup-homebrew)."
    exit 1
  fi
}

SRC_DIR="${AGENTS_GIT_SRC_DIR:-}"
if [ -z "$SRC_DIR" ]; then
  warn "AGENTS_GIT_SRC_DIR is not set — run /setup-projects first (it sets the"
  warn "env var and creates the directory), then re-run 'make sync-projects'."
  exit 1
fi
require_mikefarah_yq
command -v git >/dev/null 2>&1 || { warn "git not found."; exit 1; }

MANIFEST="projects.yaml"
[ -f "$MANIFEST" ] || { echo "No $MANIFEST — nothing to do."; exit 0; }

mkdir -p "$SRC_DIR" projects

count=0
while IFS= read -r url; do
  [ -n "$url" ] && [ "$url" != "null" ] || continue
  count=$((count + 1))
  name="$(basename "$url")"; name="${name%.git}"
  dest="$SRC_DIR/$name"
  link="projects/$name"

  if [ -d "$dest" ]; then
    say "$name already cloned in \$AGENTS_GIT_SRC_DIR"
  else
    say "cloning $url -> $dest"
    git clone "$url" "$dest" || { warn "clone failed: $url (continuing)"; continue; }
  fi

  if [ -L "$link" ]; then
    rm -f "$link"                       # refresh a possibly-stale symlink
  elif [ -e "$link" ]; then
    warn "$link exists and is not a symlink — leaving it alone"; continue
  fi
  ln -s "$dest" "$link"
done < <(yq '.projects[]' "$MANIFEST" 2>/dev/null)

if [ "$count" -eq 0 ]; then
  echo "$MANIFEST lists no projects — nothing to link."
else
  say "Synced $count project(s). Regenerate VS Code folders: make sync-workspace"
fi
