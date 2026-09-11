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
- **Issue tracker** — [beads](https://github.com/gastownhall/beads) (`bd`) in
  `.beads/`, backed by a local Dolt database. The `/setup-beads` skill installs
  and initializes it.
- **A Makefile** for onboarding and keeping everything fresh.
- **Toolchains via [asdf](https://asdf-vm.com) (v0.16+)** — node/pnpm/python/uv/go/ruby/rust
  are all managed through asdf. Every workspace pins python + uv + nodejs by default.
- **External skills via [skills.sh](https://skills.sh)** (`npx skills`) — add
  published skill collections as editable copies, tracked in `skills-lock.json`.

## Requirements

- **Homebrew** — a hard requirement; the package manager used to install
  foundational tooling (including asdf). The `/setup-homebrew` skill sets it up.
- **asdf v0.16+** — a hard requirement (all language toolchains run through it).
  The `/setup-asdf` skill installs and configures it for you (via Homebrew).
- **beads (`bd`)** — a hard requirement; the issue tracker the workspace records
  work in. The `/setup-beads` skill installs it (via Homebrew) and initializes
  the local Dolt database.
- git, and one of the supported agent harnesses (`claude`, `codex`, …).

## Quick start

This template is **agent-first**: you let an agent run the multi-step setup
rather than running each command yourself (see
[ADR 0001](./docs/adr/0001-agent-first-task-execution.md)). Pick your harness:

```bash
git clone --recurse-submodules <this-workspace-url>
cd <workspace>

# 1. Provision prerequisites + toolchains (agent-driven, in order). Pick a harness:
claude "/setup-homebrew set up Homebrew, then /setup-asdf for this workspace's toolchains, then /setup-beads, then run make setup"
codex  "/setup-homebrew set up Homebrew, then /setup-asdf for this workspace's toolchains, then /setup-beads, then run make setup"

# 2. Add your first project (the agent can do this too, via the add-submodule skill):
make add-submodule URL=<git-url> DIR=<dir>
```

Prefer to drive it yourself? The mechanical steps are always runnable directly:

```bash
make setup    # submodules, pointers, beads, VS Code sync (warns if asdf missing)
```

`make setup` never installs asdf itself — that's the agent layer's job — but it
detects whether asdf is configured and points you at `/setup-asdf` if not.

## Agent skills

Multi-step, environment-adaptive procedures live as skills in `.agents/skills/`
and are run by an agent (any harness):

- **setup-homebrew** — install/configure Homebrew (run first; asdf installs via brew).
- **setup-asdf** — install/configure asdf v0.16+, the blessed plugins, shims,
  and this workspace's toolchains.
- **setup-beads** — install the `bd` issue tracker and initialize the local Dolt
  database without clobbering the harness-agnostic agent files.
- **add-submodule** — add a project as a submodule and wire it into the workspace.
- **update-workspace** — refresh submodules, skills, and dependencies.

Add **external** skills from the [skills.sh](https://skills.sh) ecosystem with
`npx skills@latest add <owner/repo> -a universal` — they land as editable copies
under `.agents/skills/` and are tracked in `skills-lock.json`. `make
update-agent-skills` keeps them current. See
[ADR 0002](./docs/adr/0002-external-skills-via-skills-cli.md).

## Make targets (mechanical, harness-agnostic)

```
make setup              One-time onboarding after cloning
make update-submodules  Pull every submodule to latest
make update-agent-deps  Update dependencies in each submodule
make update-agent-skills Refresh external skills via `npx skills update`
make update             All three of the above
make add-submodule      Add a project submodule (URL=… DIR=… BRANCH=…)
make sync-workspace     Regenerate the VS Code folder list from .gitmodules
make help               List everything
```

## Design principles

1. **Agnostic first.** Real content lives in `AGENTS.md` / `.agents/`. Never in
   `CLAUDE.md` / `.claude/` — those only point back.
2. **Agent-first, mechanical underneath.** Multi-step setup is run by an agent
   via skills; the Makefile stays deterministic and never calls a harness.
   See [ADR 0001](./docs/adr/0001-agent-first-task-execution.md).
3. **Homebrew + asdf for all toolchains.** Homebrew is the foundational package
   manager; node/pnpm/python/uv/go/ruby/rust run through asdf v0.16+ (installed
   via brew); per-workspace versions live in `.tool-versions`.
4. **Submodules own their code.** Commit code inside the submodule, then record
   the pointer in the parent repo.
5. **Nothing goes stale.** `make update` refreshes submodules, deps, and skills.

See [`AGENTS.md`](./AGENTS.md) for the full working guide.
