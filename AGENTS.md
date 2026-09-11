# Agent Workspace

This is the **canonical, harness-agnostic** instruction file for this workspace.
Every AI harness (Claude Code, Cursor, Aider, Copilot, etc.) reads its own
convention file, but those files are just **pointers back here**. Edit this
file — never the harness-specific ones.

> Pointers: `CLAUDE.md` → `@AGENTS.md`, `.claude/skills` → `.agents/skills`,
> `.cursor/rules` → `.agents/`. See "Harness pointers" below.

## What this workspace is

An **agent workspace** is a parent directory that groups several projects
(referenced as **symlinks** to shared clones) so an agent — and a human in VS
Code — can work across all of them at once. It bundles:

- **Project references** — a committed `projects.yaml` manifest lists clone URLs;
  each project is cloned once into `$AGENTS_GIT_SRC_DIR` and symlinked into
  `projects/`. The workspace pins no project commits (see
  `docs/adr/0004-projects-as-symlinks-not-submodules.md` and `CONTEXT.md`).
- **Agent instructions** — this file (`AGENTS.md`).
- **Agent skills** — reusable procedures in `.agents/skills/`.
- **An issue tracker** — [beads](https://github.com/gastownhall/beads) (`bd`) in `.beads/`.

It is simultaneously a **VS Code multi-root workspace** (`*.code-workspace`),
so every symlinked project shows up as a folder in the editor.

**Homebrew, [asdf](https://asdf-vm.com) v0.16+, and [beads](https://github.com/gastownhall/beads)
(`bd`) are hard requirements**, on the same level. Homebrew is the package
manager that installs the other two (including asdf itself), so set it up first.
Homebrew also installs the small CLI utilities the workspace tooling relies on:
**jq** (parses JSON) and **yq** (parses the project manifest). node/pnpm/python/uv/go/ruby/rust are all managed by asdf; each workspace pins
versions in `.tool-versions` (python + uv + nodejs by default — nodejs provides
`npx` for skill management). beads tracks work as issues in a local Dolt
database under `.beads/`.

**Agent-first.** Multi-step, environment-adaptive tasks (installing asdf,
provisioning toolchains, …) are run by *you, the agent*, via skills — not by a
human running commands. The Makefile is the mechanical, deterministic layer and
never invokes a harness. See `docs/adr/0001-agent-first-task-execution.md`.

## Layout

```
.
├── AGENTS.md                 # ← you are here (canonical instructions)
├── CLAUDE.md                 # pointer → @AGENTS.md
├── CONTEXT.md                # glossary: workspace / project / manifest terms
├── *.code-workspace          # VS Code multi-root workspace (one folder per project)
├── Makefile                  # setup / update-projects / update-agent-skills / update-agent-deps
├── projects.yaml             # manifest: clone URLs of the projects this workspace references
├── projects/                 # one symlink per project → $AGENTS_GIT_SRC_DIR/<name> (git-ignored)
├── .tool-versions            # asdf toolchain pins (python + uv + nodejs by default)
├── .agents/
│   └── skills/               # agent skills — built-in (setup-homebrew, setup-asdf, setup-beads, setup-projects, add-project, …) + external copies via `npx skills`
├── skills-lock.json          # lockfile for external skills (created when you add the first one)
├── .claude/                  # Claude Code harness pointers (skills symlink, settings)
├── .vscode/                  # recommended extensions + shared editor settings
├── .beads/                   # beads issue tracker (local Dolt db, git-ignored; README committed)
├── docs/adr/                 # architecture decision records (0001 = agent-first, 0004 = projects-as-symlinks)
└── scripts/                  # helper scripts used by the Makefile
```

Project clones themselves live outside the workspace, in `$AGENTS_GIT_SRC_DIR`
(default `~/agents/git_repos`), shared across every workspace that references
them.

## Working rules

1. **Harness-agnostic first.** Put instructions in `AGENTS.md` and skills in
   `.agents/skills/`. Never write harness-specific files (`CLAUDE.md`,
   `.cursor/rules`, …) with real content — they only point here.
2. **Projects own their code; the workspace only references them.** A project's
   clone lives in `$AGENTS_GIT_SRC_DIR` and is symlinked into `projects/`. Commit
   code changes inside the project's own repo. The workspace pins no commits, so
   there is no parent pointer to update. Never commit the symlinks — they're
   git-ignored (only `projects.yaml` and `projects/README.md` are tracked).
3. **Keep the workspace in sync.** After adding/removing a project (editing
   `projects.yaml` or the symlinks), run `make sync-workspace` so the
   `.code-workspace` folder list matches `projects/`. `add-project` /
   `sync-projects` do this for you.
4. **Track work in beads.** Use `bd` (`bd create`, `bd ready`, `bd list`) for
   issues rather than scattering TODOs. See "Issue tracking (beads)" below; run
   `bd prime` for the full, current workflow.
5. **Don't let projects go stale.** Run `make update-projects` regularly.

## Skills

Skills live in `.agents/skills/<name>/SKILL.md`. Available in this template:

- **setup-homebrew** — install/configure Homebrew. Run this first when
  onboarding a machine (asdf installs via brew).
- **setup-asdf** — install/configure asdf v0.16+, the blessed plugins, shims,
  and this workspace's toolchains. Run after `setup-homebrew`.
- **setup-beads** — install the `bd` issue tracker (via Homebrew) and initialize
  the workspace's local Dolt database with `--skip-agents` so the harness files
  stay untouched. Run after `setup-homebrew`.
- **setup-projects** — provision `$AGENTS_GIT_SRC_DIR` (env var + directory) and
  clone+symlink the projects in `projects.yaml`. Run after `setup-homebrew`.
- **add-project** — add a new project: record its URL in `projects.yaml`, clone
  it, symlink it into `projects/`, and register it in the VS Code workspace +
  issue tracker.
- **update-workspace** — refresh projects, skills, and dependencies so nothing
  goes stale.

Invoke a skill by reading its `SKILL.md` and following the procedure.

**External skills** from the [skills.sh](https://skills.sh) ecosystem are added
with `npx skills@latest add <owner/repo> -a universal` (installs editable copies
into `.agents/skills/`, tracked in `skills-lock.json`) and refreshed with `make
update-agent-skills`. See `docs/adr/0002-external-skills-via-skills-cli.md`.

## Issue tracking (beads)

This workspace tracks work with **bd (beads)**. Issues live in a local **Dolt**
database under `.beads/` (git-ignored); `.beads/issues.jsonl` is a passive
export, not the source of truth. Cross-machine sync is `bd dolt push`/`pull`,
not committed files.

These instructions live **here, in `AGENTS.md`, only** — the canonical,
harness-agnostic home. `CLAUDE.md` picks them up via `@AGENTS.md`. Do **not**
let `bd init` write its own integration files (it clobbers `CLAUDE.md` and
duplicates this); `/setup-beads` initializes the database with `--skip-agents`.
See `docs/adr/0003-beads-harness-agnostic-integration.md`.

Quick reference:

```bash
bd ready                                    # find unblocked work
bd create "Title" --type task --priority 2  # file an issue
bd show <id>                                # detail
bd update <id> --claim                      # claim work atomically
bd close <id>                               # complete work
bd dolt push                                # sync issues to the remote
```

Run `bd prime` for the full, up-to-date workflow context.

## Common commands

| Command | Purpose |
| --- | --- |
| `make setup` | One-time onboarding after cloning (projects, pointers, deps, beads). |
| `make sync-projects` | Clone+symlink every project in `projects.yaml` (needs `$AGENTS_GIT_SRC_DIR`). |
| `make update-projects` | `git pull` every linked project to its default branch. |
| `make update-agent-skills` | Refresh external skills via `npx skills update` (tracked in `skills-lock.json`). |
| `make update-agent-deps` | Update project dependencies (npm/pnpm/yarn/pip/…) in each project. |
| `make add-project URL=…` | Add a new project (record, clone, symlink) and wire it up. |
| `make sync-workspace` | Regenerate the `.code-workspace` folder list by scanning `projects/`. |
| `make help` | List all targets. |

## Harness pointers

These files exist only to redirect a specific harness back to the canonical
sources. Do not put real content in them.

- `CLAUDE.md` — contains `@AGENTS.md` (Claude Code import).
- `.claude/skills` — symlink to `../.agents/skills`.
- `.claude/settings.json` — Claude Code settings (minimal).
