# Domain Docs

How the engineering skills should consume this workspace's domain documentation
when exploring the codebase.

## Before exploring, read these

- **`CONTEXT-MAP.md`** at the workspace root — this is a **multi-context**
  workspace, so the map is authoritative. It indexes one context per project.
  Read each `CONTEXT.md` it points at that is relevant to the topic.
- **`CONTEXT.md`** at the root — the workspace's own vocabulary (how projects are
  referenced, skills, toolchains, issue tracking).
- **`docs/adr/`** at the root — workspace-wide architectural decisions. For work
  inside a project, also read that project's `projects/<name>/docs/adr/`.

If any of these files don't exist, **proceed silently**. Don't flag their
absence; don't suggest creating them upfront. The producer skill
(`/grill-with-docs`) creates them lazily when terms or decisions actually get
resolved — and `CONTEXT-MAP.md` is maintained as projects are added/removed.

## File structure

This workspace is multi-context (`CONTEXT-MAP.md` is present at the root). Each
project referenced by the workspace is its own context, and its context files
live in the project's own repo, reached through the `projects/` symlink:

```
/
├── CONTEXT-MAP.md                     ← index of all contexts (maintained by agents)
├── CONTEXT.md                         ← the workspace's own vocabulary
├── docs/adr/                          ← workspace-wide decisions
└── projects/
    ├── ordering/                      → $AGENTS_GIT_SRC_DIR/ordering (symlink)
    │   ├── CONTEXT.md                 ← context-specific glossary
    │   └── docs/adr/                  ← context-specific decisions
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal,
a hypothesis, a test name), use the term as defined in the relevant `CONTEXT.md`.
Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either
you're inventing language the project doesn't use (reconsider) or there's a real
gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
