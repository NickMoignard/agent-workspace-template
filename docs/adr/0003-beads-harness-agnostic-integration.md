# 3. Integrate beads without letting it own the harness files

Date: 2026-09-11

## Status

Accepted

## Context

beads (`bd`) is the workspace issue tracker and a hard requirement, on the same
level as Homebrew and asdf. It installs via Homebrew (`brew install beads`).

Modern `bd` (1.x) is helpful to a fault. A plain `bd init`:

- **overwrites `AGENTS.md`** with its own multi-kilobyte instruction file,
- **creates a real-content `CLAUDE.md`** with a "beads integration" block,
- installs `.claude/settings.json` and `.codex/` hooks, and
- drops a `.agents/skills/beads/` skill.

That directly violates this workspace's founding rule: `AGENTS.md` is the single
canonical, harness-agnostic instruction file, and `CLAUDE.md` / `.claude/` are
pointers with **no real content**. We hit exactly this when onboarding a fresh
clone: `bd init` duplicated guidance into `CLAUDE.md` and `AGENTS.md` at once.

beads also changed storage: the backend is now **Dolt**, not the old
JSONL-is-source-of-truth + SQLite-cache model. Issues live in a local Dolt
database (`.beads/embeddeddolt/`); sync is `bd dolt push`/`pull` over
`refs/dolt/data`, and `.beads/issues.jsonl` is only a passive export. The
template's `.beads/README.md` and `.gitignore` still described the old model.

`bd init` exposes `--skip-agents` (skip AGENTS.md and Claude/Codex generation),
`--skip-hooks`, and `--init-if-missing` (idempotent for scaffolds).

## Decision

- **The workspace owns `AGENTS.md`, not beads.** The canonical beads
  instructions live once, in the top-level `AGENTS.md` ("Issue tracking
  (beads)"), seeded from `bd onboard`'s minimal snippet. `CLAUDE.md` stays a
  pure `@AGENTS.md` pointer.
- **Always initialize with `--skip-agents`.** Both the mechanical path
  (`scripts/setup.sh`) and the agent path (`/setup-beads` skill) run
  `bd init --skip-agents --skip-hooks --init-if-missing`. Never a plain
  `bd init` in this workspace.
- **beads is a hard requirement with its own skill.** `/setup-beads` mirrors
  `/setup-homebrew` and `/setup-asdf`: it installs `bd` via Homebrew and runs
  the controlled init. Documented as a requirement in `AGENTS.md` and `README`.
- **Treat storage as Dolt.** `.beads/` ships only a curated `README.md`; the
  Dolt database and per-machine runtime are git-ignored. `config.yaml` /
  `metadata.json` are generated per workspace on first init, not baked into the
  template.

## Consequences

- The pointer-only rule holds even though bd wants to write everywhere; the
  price is remembering to pass `--skip-agents` (enforced in the script and the
  skill, and called out in `AGENTS.md`).
- Agent instructions are not auto-updated by bd. If bd's recommended snippet
  changes, we re-sync the `AGENTS.md` section by hand from `bd onboard`. `bd
  prime` still provides the dynamic, always-current workflow at runtime.
- Sync is via Dolt remotes, not committed files — a workspace that wants durable
  cross-machine issues configures a Dolt remote and runs `bd dolt push`.
- Optional session/git integration (`bd hooks install`, a `bd prime` SessionStart
  hook) is left to the user as a per-clone choice; it is not committed state.
