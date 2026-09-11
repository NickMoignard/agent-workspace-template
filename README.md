# Agent Workspace Template

A git repository template for creating a **harness-agnostic agent workspace** —
a parent directory that groups several projects (as git submodules) so an AI
agent and a human in VS Code can work across all of them at once.

Select this template when creating a new workspace, then run `make setup`.

## What you get

- **Harness-agnostic agent config** — canonical instructions in `AGENTS.md`;
  harness-specific files (`CLAUDE.md`, `.claude/`) are just pointers to it.
- **VS Code multi-root workspace** — `workspace.code-workspace` lists every
  submodule as a folder, with recommended extensions and shared settings
  (`.vscode/`). The folder list stays in sync with `.gitmodules` automatically.
- **Agent skills** (`.agents/skills/`) — `add-submodule` and `update-workspace`,
  plus a manifest for syncing external skill repos.
- **Issue tracker** — [beads](https://github.com/steveyegge/beads) in `.beads/`.
- **A Makefile** for onboarding and keeping everything fresh.

## Quick start

```bash
git clone --recurse-submodules <this-workspace-url>
cd <workspace>
make setup                                   # onboarding
make add-submodule URL=<git-url> DIR=<dir>   # add your first project
```

## Make targets

```
make setup              One-time onboarding after cloning
make update-submodules  Pull every submodule to latest
make update-agent-deps  Update dependencies in each submodule
make update-agent-skills Sync external skills from .agents/skills.manifest
make update             All three of the above
make add-submodule      Add a project submodule (URL=… DIR=… BRANCH=…)
make sync-workspace     Regenerate the VS Code folder list from .gitmodules
make help               List everything
```

## Design principles

1. **Agnostic first.** Real content lives in `AGENTS.md` / `.agents/`. Never in
   `CLAUDE.md` / `.claude/` — those only point back.
2. **Submodules own their code.** Commit code inside the submodule, then record
   the pointer in the parent repo.
3. **Nothing goes stale.** `make update` refreshes submodules, deps, and skills.

See [`AGENTS.md`](./AGENTS.md) for the full working guide.
