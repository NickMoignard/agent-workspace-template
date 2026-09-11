# Agent Workspace

This is the **canonical, harness-agnostic** instruction file for this workspace.
Every AI harness (Claude Code, Cursor, Aider, Copilot, etc.) reads its own
convention file, but those files are just **pointers back here**. Edit this
file — never the harness-specific ones.

> Pointers: `CLAUDE.md` → `@AGENTS.md`, `.claude/skills` → `.agents/skills`,
> `.cursor/rules` → `.agents/`. See "Harness pointers" below.

## What this workspace is

An **agent workspace** is a parent directory that groups several projects
(added as **git submodules**) so an agent — and a human in VS Code — can work
across all of them at once. It bundles:

- **Project source code** — each project is a git submodule under this root.
- **Agent instructions** — this file (`AGENTS.md`).
- **Agent skills** — reusable procedures in `.agents/skills/`.
- **An issue tracker** — [beads](https://github.com/steveyegge/beads) in `.beads/`.

It is simultaneously a **VS Code multi-root workspace** (`*.code-workspace`),
so every submodule shows up as a folder in the editor.

## Layout

```
.
├── AGENTS.md                 # ← you are here (canonical instructions)
├── CLAUDE.md                 # pointer → @AGENTS.md
├── *.code-workspace          # VS Code multi-root workspace (one folder per submodule)
├── Makefile                  # setup / update-submodules / update-agent-skills / update-agent-deps
├── .agents/
│   ├── skills/               # canonical agent skills (add-submodule, update-workspace, …)
│   └── skills.manifest       # external skill repos to sync on `make update-agent-skills`
├── .claude/                  # Claude Code harness pointers (skills symlink, settings)
├── .vscode/                  # recommended extensions + shared editor settings
├── .beads/                   # issue tracker database + JSONL
├── scripts/                  # helper scripts used by the Makefile
└── <project-a>/ <project-b>/ # git submodules (the actual source code)
```

## Working rules

1. **Harness-agnostic first.** Put instructions in `AGENTS.md` and skills in
   `.agents/skills/`. Never write harness-specific files (`CLAUDE.md`,
   `.cursor/rules`, …) with real content — they only point here.
2. **Submodules are the source of truth for code.** Never commit changes to a
   submodule's tracked files from the parent repo; `cd` into the submodule,
   commit and push there, then record the new pointer in the parent.
3. **Keep the workspace in sync.** After adding/removing a submodule, run
   `make sync-workspace` so the `.code-workspace` folder list matches
   `.gitmodules`. The `add-submodule` skill does this for you.
4. **Track work in beads.** Use `bd` (`bd create`, `bd ready`, `bd list`) for
   issues rather than scattering TODOs.
5. **Don't let submodules go stale.** Run `make update-submodules` regularly.

## Skills

Skills live in `.agents/skills/<name>/SKILL.md`. Available in this template:

- **add-submodule** — add a new project as a submodule and register it in the
  VS Code workspace + issue tracker.
- **update-workspace** — refresh submodules, skills, and dependencies so
  nothing goes stale.

Invoke a skill by reading its `SKILL.md` and following the procedure.

## Common commands

| Command | Purpose |
| --- | --- |
| `make setup` | One-time onboarding after cloning (submodules, symlinks, deps, beads). |
| `make update-submodules` | Pull every submodule to its latest tracked branch. |
| `make update-agent-skills` | Sync external skills listed in `.agents/skills.manifest`. |
| `make update-agent-deps` | Update project dependencies (npm/pnpm/yarn/pip/…) in each submodule. |
| `make add-submodule URL=… DIR=…` | Add a new project submodule and wire it up. |
| `make sync-workspace` | Regenerate the `.code-workspace` folder list from `.gitmodules`. |
| `make help` | List all targets. |

## Harness pointers

These files exist only to redirect a specific harness back to the canonical
sources. Do not put real content in them.

- `CLAUDE.md` — contains `@AGENTS.md` (Claude Code import).
- `.claude/skills` — symlink to `../.agents/skills`.
- `.claude/settings.json` — Claude Code settings (minimal).
