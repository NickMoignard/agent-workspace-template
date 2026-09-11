# Context Map

This is a **multi-context** agent workspace: it groups several projects, and each
project is its own bounded context with its own domain language and decisions.
This file is the index of those contexts. **Agents must keep it current** — when
a project is added (`make add-project`) or removed, register or remove its entry
here and update the relationships. Treat it as maintained, not optional.

See `CONTEXT.md` for the workspace's own vocabulary and `docs/agents/domain.md`
for how skills consume these files. Per-context ADRs live in
`projects/<name>/docs/adr/`; workspace-wide decisions stay in the root
`docs/adr/`.

## Contexts

- [Workspace tooling](./CONTEXT.md) — the workspace itself: how projects are
  referenced (manifest + symlinks), skills, toolchains, issue tracking.
- _One entry per referenced project, pointing at its own `CONTEXT.md` (read
  through the symlink; it lives in the project's repo):_
  - `[<name>](./projects/<name>/CONTEXT.md)` — <one-line description>

## Relationships

- _How the contexts relate: shared types, events, cross-project dependencies.
  Empty until the workspace references more than one project._
