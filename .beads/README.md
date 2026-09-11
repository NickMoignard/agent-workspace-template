# Issue tracker (beads)

This workspace tracks work with [beads](https://github.com/steveyegge/beads) —
a dependency-aware, git-friendly issue tracker driven by the `bd` CLI.

## How it works

- Issues live in a JSONL file in this directory (committed to git — it is the
  source of truth and merges cleanly).
- `bd` maintains a local SQLite `*.db` cache alongside it for fast queries.
  The cache is git-ignored and rebuilt from the JSONL automatically.

## Setup

`make setup` runs `bd import` / `bd init` for you. To do it manually:

```bash
bd init          # first time, creates the JSONL + db in .beads/
bd import        # rebuild the local db cache from committed JSONL
```

## Everyday use

```bash
bd create "Title" -d "Description"   # file an issue
bd ready                             # issues with no unmet dependencies
bd list                              # all open issues
bd show <id>                         # detail
bd close <id>                        # mark done
```

Agents should record work here rather than leaving loose TODOs in code.
