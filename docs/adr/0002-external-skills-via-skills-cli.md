# 2. Manage external agent skills with the skills.sh CLI

Date: 2026-09-11

## Status

Accepted

## Context

Workspaces want to pull in agent skills published by others (e.g.
`samber/cc-skills-golang`, `mattpocock/skills`). These upstream repos are
**collections**: many skills nested under `skills/…/SKILL.md`, sometimes two
levels deep. A harness discovers skills at `.agents/skills/<name>/SKILL.md`
(one level), so a raw `git clone` of a collection into `.agents/skills/<repo>`
buries the skills too deep to be found.

Our first cut (`.agents/skills.manifest` + a git-clone sync script) assumed one
skill per repo and had no answer for collections, flattening, name collisions,
or updates.

The [skills.sh](https://skills.sh) ecosystem ships a CLI (`npx skills`) that
solves exactly this: it discovers skills in a collection, lets you select which
to take, flattens them into the agent directory, records them in a
`skills-lock.json`, and updates them on demand. It supports a `universal` agent
target that writes to `.agents/` — our canonical harness-agnostic location.

## Decision

External skills are managed with the `skills` CLI, not a bespoke manifest:

- **Add:** `npx skills@latest add <owner/repo> -a universal [--all | -s <name>]`.
  Installs editable **copies** into `.agents/skills/<skill>/` and records them in
  `skills-lock.json`.
- **Source of truth:** `skills-lock.json` (committed), plus the copied skill
  files themselves (committed — they are ours to edit; the workspace stays
  self-contained and offline-capable).
- **Update:** `make update-agent-skills` runs `npx skills update -p -y`.
- **Requires nodejs** for `npx`. nodejs is therefore promoted to a baseline
  toolchain pinned in `.tool-versions` for every workspace (alongside python +
  uv). This is consistent with ADR 0001: `/setup-asdf` provisions it.

The old `.agents/skills.manifest` and its git-clone sync are removed.

## Consequences

- Collections, selection, flattening, and updates are handled by a maintained
  ecosystem tool instead of our own script.
- The workspace's own built-in skills (`setup-asdf`, `add-project`, …) live
  alongside externally-added ones in `.agents/skills/`; the lockfile
  distinguishes what `skills update` manages.
- nodejs is now always installed, even in workspaces that ship no JS code —
  accepted, because `npx` underpins skill management everywhere.
- `make update-agent-skills` depends on the agent layer (nodejs via asdf); it
  degrades gracefully with a pointer to `/setup-asdf` when npx is absent.
- Skills run with full agent permissions — review added skills before use.
