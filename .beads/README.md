# Issue tracker (beads)

This workspace tracks work with [beads](https://github.com/gastownhall/beads) —
a dependency-aware, git-friendly issue tracker driven by the `bd` CLI. beads is
a **hard requirement** for the workspace, on the same level as Homebrew and asdf.

## How it works

- Issues live in a local **Dolt** database in this directory (`embeddeddolt/`).
  Dolt is a version-controlled SQL database; the db itself is git-ignored.
- Cross-machine sync and backup use **Dolt remotes** (`bd dolt push` / `bd dolt
  pull`), stored under `refs/dolt/data` on your git remote — separate from your
  code's branches. Committing the database files is *not* how beads syncs.
- `.beads/issues.jsonl` (when present) is a **passive export** for viewers and
  interchange, not the source of truth. Don't `bd import` it during normal use.

## Setup

`/setup-beads` (or `make setup`) initializes the local database for you with a
controlled, harness-agnostic init:

```bash
bd init --skip-agents --skip-hooks --init-if-missing
```

`--skip-agents` is important: a plain `bd init` overwrites `AGENTS.md`, creates a
real-content `CLAUDE.md`, and installs harness hooks — which breaks this
workspace's rule that `CLAUDE.md` is a pointer only. The canonical beads
instructions live once in the top-level `AGENTS.md`. See
`../docs/adr/0003-beads-harness-agnostic-integration.md`.

## Everyday use

```bash
bd ready                                    # issues with no unmet dependencies
bd create "Title" --type task --priority 2  # file an issue
bd list                                     # all open issues
bd show <id>                                # detail
bd update <id> --claim                      # claim work atomically
bd close <id>                               # mark done
bd dolt push                                # sync issues to the remote
```

Run `bd prime` for the full, up-to-date workflow context. Agents should record
work here rather than leaving loose TODOs in code.
