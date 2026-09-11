#!/usr/bin/env bash
# Add a project to the workspace: record its URL in projects.yaml, clone it into
# $AGENTS_GIT_SRC_DIR, symlink it into projects/, sync the VS Code workspace,
# install its dependencies, and file a beads onboarding issue. Usage:
#
#     scripts/add-project.sh <git-url>
#
# Called by `make add-project URL=…`. See docs/adr/0004.
set -euo pipefail
cd "$(dirname "$0")/.."

URL="${1:-}"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

# Need mikefarah/yq (Go), not python-yq (the apt/pip jq-wrapper of the same name).
require_mikefarah_yq() {
  command -v yq >/dev/null 2>&1 || { warn "yq not found — run /setup-homebrew."; exit 1; }
  if ! yq --version 2>&1 | grep -qi mikefarah; then
    warn "The 'yq' on PATH is not mikefarah/yq (found: $(yq --version 2>&1 | head -1))."
    warn "Install it with 'brew install yq' and ensure Homebrew's bin precedes"
    warn "/usr/bin on PATH (see /setup-homebrew)."
    exit 1
  fi
}

if [ -z "$URL" ]; then
  echo "Usage: make add-project URL=<git-url>" >&2
  exit 2
fi
require_mikefarah_yq

name="$(basename "$URL")"; name="${name%.git}"
MANIFEST="projects.yaml"
[ -f "$MANIFEST" ] || printf 'projects: []\n' > "$MANIFEST"

# Append to the manifest unless it's already listed.
if yq '.projects[]' "$MANIFEST" 2>/dev/null | grep -qxF "$URL"; then
  say "$URL already in $MANIFEST"
else
  yq -i ".projects += [\"$URL\"]" "$MANIFEST"
  say "Added $URL to $MANIFEST"
fi

# Clone + symlink (mechanical), then regenerate the VS Code folder list.
say "Cloning + linking projects"
bash scripts/sync-projects.sh

say "Syncing VS Code workspace folders"
bash scripts/run-node.sh scripts/sync-workspace.mjs

# Install just this project's dependencies.
if [ -d "projects/$name" ]; then
  say "Installing dependencies for $name"
  bash scripts/update-agent-deps.sh --install "projects/$name" \
    || warn "dependency install had issues (continuing)."
fi

# Optionally file a beads issue to onboard the new project.
if command -v bd >/dev/null 2>&1; then
  bd create "Onboard project: $name" \
    -d "Newly referenced from $URL. Review its README, wire up build/CI, and confirm it works in the workspace." \
    >/dev/null 2>&1 && say "Filed a beads onboarding issue for $name" || true
fi

cat <<DONE

Added '$name'. Commit the workspace changes (not the symlink — it's git-ignored):
    git add projects.yaml workspace.code-workspace
    git commit -m "Add $name project"
DONE
