# Issue tracker: beads (bd)

Issues, PRDs, and triage state for this workspace live in **beads** — a local
Dolt database driven by the `bd` CLI. Not GitHub Issues, not files. See the
"Issue tracking (beads)" section of `AGENTS.md` and run `bd prime` for the full
workflow.

## Conventions

- **Create:** `bd create "Title" --type <task|bug|feature|epic> -p <0-3> -d "…"`.
  Capture the returned id (e.g. `workspace-x1y`).
- **Find work:** `bd ready` (unblocked), `bd list`, `bd show <id>`.
- **Claim:** `bd update <id> --claim`.
- **Triage state:** apply the role labels from `triage-labels.md` with
  `bd label add <id> <label>` (remove the previous one as it moves through the
  state machine).
- **Conversation:** `bd comment <id> "…"` (or `bd note`).
- **Dependencies:** `bd dep add <id> --blocks <other>` / `bd link` to chain issues.
- **Close:** `bd close <id>`. **Sync:** `bd dolt push`.

## PRDs

A PRD is an **epic bead**: `bd create "…" --type epic` with the spec in its
description (or a markdown doc referenced from it). Implementation issues are
created as separate beads and linked to the epic via `bd dep`.

## When a skill says "publish to the issue tracker"

Run `bd create …` and record the returned id.

## When a skill says "fetch the relevant ticket"

Run `bd show <id>` (the user normally passes the id).
