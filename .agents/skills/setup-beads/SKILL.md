---
name: setup-beads
description: Install the beads issue tracker (`bd`) and initialize this workspace's local Dolt database without clobbering the harness-agnostic agent files. Ensures `bd` is present (via Homebrew), then runs a controlled `bd init --skip-agents` so AGENTS.md/CLAUDE.md/.claude stay as-is. Use when onboarding a machine, when `bd` is missing, or when `make setup` reports beads is not installed.
---

# Set up beads for this workspace

beads (`bd`) is a **hard requirement** for every agent workspace, on the same
level as Homebrew and asdf. It is the dependency-aware issue tracker the
workspace uses to record work instead of scattering loose TODOs. Issues live in
a local **Dolt** database under `.beads/`; cross-machine sync is `bd dolt
push`/`pull`, not committed files.

You are an agent running this end-to-end. Inspect state, adapt to the OS/shell,
and debug failures yourself rather than handing them back to the user.

## Why the `--skip-agents` init matters

A plain `bd init` is aggressive: it **overwrites `AGENTS.md`**, **creates a
real-content `CLAUDE.md`**, installs `.claude/settings.json` + `.codex` hooks,
and drops a `.agents/skills/beads/` skill. That breaks this workspace's core
rule that `CLAUDE.md` is a pointer with no real content, and it duplicates
guidance across files.

This workspace already carries the canonical beads instructions **once**, in
`AGENTS.md` (see its "Issue tracking (beads)" section). So we initialize beads
with `--skip-agents`: create the database, touch none of the agent files. See
`docs/adr/0003-beads-harness-agnostic-integration.md`.

## Steps

### 0. Prerequisite: Homebrew

beads is installed via Homebrew, a hard requirement on the same level. If `brew`
is missing, run `/setup-homebrew` first, then continue here.

### 1. Ensure `bd` is installed

```bash
bd --version   # any recent 1.x is fine
```

- **Missing** → `brew install beads`.
- **Present** → optionally `brew upgrade beads` to stay current.

(The Homebrew formula is `beads`; it provides the `bd` binary. Upstream is
[gastownhall/beads](https://github.com/gastownhall/beads).)

### 2. Initialize the workspace database (harness-agnostic)

Create the local Dolt database **without** letting bd write or overwrite any
agent-instruction or harness files:

```bash
BD_NON_INTERACTIVE=1 bd init --skip-agents --skip-hooks --init-if-missing
```

- `--skip-agents` — do not generate/overwrite `AGENTS.md`, `CLAUDE.md`,
  `.claude/`, or `.codex/`. The canonical instructions already live in
  `AGENTS.md`.
- `--skip-hooks` — don't install git hooks in the mechanical path (offer them
  separately in step 4 if the user wants auto-flush on commit).
- `--init-if-missing` — idempotent: if the workspace is already initialized,
  exit cleanly instead of failing.

The prefix defaults to the directory name, which is the right issue prefix for
the workspace; pass `-p <prefix>` only if the user wants a different one.

### 3. Verify

```bash
bd status     # database overview
bd ready      # unblocked work (empty on a fresh workspace is expected)
```

If `bd status` errors with "No active beads workspace found", step 2 didn't
create the database — re-run it and read the output.

### 4. (Optional) session + git integration

These are per-clone conveniences, not committed workspace state — offer them,
don't force them:

- `bd hooks install` — flush/commit beads data on git operations.
- `bd prime` — prints the full, up-to-date workflow context; a harness can wire
  it into a SessionStart hook so the agent never forgets the bd workflow.

## Rules

- **Never** run a plain `bd init` here — always `--skip-agents`. The workspace,
  not bd, owns `AGENTS.md`; `CLAUDE.md` stays a pointer.
- Install non-interactively (`BD_NON_INTERACTIVE=1`); never leave a prompt
  hanging.
- The Dolt database and per-machine runtime under `.beads/` are local and
  git-ignored; `.beads/issues.jsonl` is a passive export, not the source of
  truth. Sync with `bd dolt push`, not by committing the db.
- On any failure, diagnose and fix in place — you're the agent, not the user.
