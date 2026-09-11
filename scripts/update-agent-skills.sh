#!/usr/bin/env bash
# Sync external agent skills declared in .agents/skills.manifest.
#
# Manifest format (whitespace-separated, '#' comments and blank lines ignored):
#
#     <name>   <git-url>                              [ref]
#     example  https://github.com/org/agent-skills    main
#
# Each entry is cloned to .agents/skills/<name> and kept up to date with a
# fast-forward pull. Locally-authored skills (not listed in the manifest) are
# never touched.
set -euo pipefail
cd "$(dirname "$0")/.."

MANIFEST=".agents/skills.manifest"
DEST_ROOT=".agents/skills"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

if [ ! -f "$MANIFEST" ]; then
  echo "No $MANIFEST found — nothing to sync."
  exit 0
fi

count=0
# Read three columns; ref is optional.
while read -r name url ref _rest || [ -n "$name" ]; do
  case "$name" in ""|\#*) continue;; esac   # skip blanks / comments
  [ -n "${url:-}" ] || { warn "skipping '$name' — no git URL"; continue; }
  dest="$DEST_ROOT/$name"
  count=$((count+1))

  if [ -d "$dest/.git" ]; then
    say "updating skill '$name'"
    git -C "$dest" fetch --quiet origin
    git -C "$dest" checkout --quiet "${ref:-HEAD}" 2>/dev/null || true
    git -C "$dest" pull --ff-only --quiet || warn "could not fast-forward '$name'"
  else
    say "cloning skill '$name' from $url"
    rm -rf "$dest"
    git clone --quiet ${ref:+--branch "$ref"} "$url" "$dest" \
      || warn "failed to clone '$name'"
  fi
done < "$MANIFEST"

if [ "$count" -eq 0 ]; then
  echo "Manifest has no active entries — add some external skill repos to $MANIFEST."
else
  say "Synced $count external skill(s)."
fi
