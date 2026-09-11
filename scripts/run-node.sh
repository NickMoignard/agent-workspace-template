#!/usr/bin/env bash
# Resolve a working `node` and exec it with the given arguments.
#
# The mechanical scripts (e.g. sync-workspace.mjs) must run even before
# /setup-asdf has installed the nodejs version pinned in .tool-versions —
# otherwise asdf's shim aborts with "No version is set for command node" and
# `make add-project` / `make sync-workspace` break on a fresh clone.
#
# Resolution order (first that runs wins):
#   1. `node` on PATH (respects the asdf pin) — when the pinned version exists.
#   2. a system node on PATH, outside the asdf shims dir.
#   3. a system node in a common install location.
#   4. any node already installed under asdf, bypassing the pin (newest first).
set -euo pipefail

works() { "$1" --version >/dev/null 2>&1; }

ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
shimdir="$ASDF_DATA_DIR/shims"

pick_node() {
  # 1. Whatever `node` resolves to, if the resolved version actually runs.
  if command -v node >/dev/null 2>&1 && works node; then
    command -v node; return 0
  fi

  # 2. Any node on PATH that isn't the asdf shim.
  local c
  while IFS= read -r c; do
    case "$c" in "$shimdir"/*) continue ;; esac
    works "$c" && { printf '%s\n' "$c"; return 0; }
  done < <(command -v -a node 2>/dev/null)

  # 3. Common system locations (incl. Homebrew).
  for c in /opt/homebrew/bin/node /usr/local/bin/node /usr/bin/node \
           "$(brew --prefix 2>/dev/null)/bin/node"; do
    [ -x "$c" ] && works "$c" && { printf '%s\n' "$c"; return 0; }
  done

  # 4. Any asdf-installed nodejs, newest first, bypassing the pinned version.
  local base="$ASDF_DATA_DIR/installs/nodejs" v
  if [ -d "$base" ]; then
    for v in $(ls -1 "$base" 2>/dev/null | sort -rV); do
      [ -x "$base/$v/bin/node" ] && works "$base/$v/bin/node" \
        && { printf '%s\n' "$base/$v/bin/node"; return 0; }
    done
  fi
  return 1
}

NODE="$(pick_node || true)"
if [ -z "${NODE:-}" ]; then
  echo "run-node: no working node found." >&2
  echo "  Run /setup-asdf to install the pinned nodejs (see .tool-versions)," >&2
  echo "  or install node another way." >&2
  exit 1
fi
exec "$NODE" "$@"
