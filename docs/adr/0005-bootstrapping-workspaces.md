# 5. Bootstrap new workspaces with a standalone skill, not GitHub's template button

Date: 2026-09-11

## Status

Accepted

## Context

This repo is a GitHub *template* repo. GitHub's native consumption paths — the
"Use this template" button and `gh repo create --template` — both create a
*new repo pre-filled with the contents*. But our provisioning flow is the
opposite: an empty repo is created first (by other automation), then code is
pushed into it. There was no defined way to lay the template down into an
existing empty directory, and the README's `git clone <this-workspace-url>`
actually clones the *template itself* (its history and remote), not a fresh
workspace.

We also want more than a file copy: a new workspace needs its README rewritten,
its `projects.yaml` populated, and default skills chosen. That is
environment-adaptive, agent-shaped work (per ADR 0001), not a fixed script.

## Decision

New workspaces are created by a standalone skill, **`create-agent-workspace`**,
that wraps a mechanical bootstrap script:

- **Standalone skill, its own repo.** The skill lives in
  `NickMoignard/create-agent-workspace` and is installed with the skills.sh CLI
  (`npx skills add NickMoignard/create-agent-workspace`). Being globally
  installed, an agent can run it inside an *empty* directory — the directory
  doesn't need the template's files first (no chicken-and-egg). Keeping it in
  its own repo means the meta-tool never copies itself into the workspaces it
  creates, and this template stays a pure workspace template.
- **This template is the scaffold source.** The bootstrap script fetches the
  template's default-branch **tarball**
  (`curl … /archive/refs/heads/main.tar.gz | tar xz`) into the target directory.
  No `.git` (so the workspace's own empty repo / history is preserved and the
  template's history is not inherited), no auth for a public repo, no extra deps.
- **Resets vs carry-over.** The script leaves `projects.yaml` empty and beads
  uninitialized (a fresh identity comes from `/setup-beads`), and drops the
  template-only README and this bootstrap ADR. It carries over the model docs —
  `CONTEXT.md`, `CONTEXT-MAP.md`, and ADRs 0001–0004 — so each workspace keeps
  the rationale for how it operates.
- **Then a guided conversation.** After the copy, the skill runs a grill-style
  setup: workspace name/purpose → a rewritten README, initial projects →
  `projects.yaml`, default skills → `npx skills add`, then the standard
  `/setup-*` → `make setup` chain.

`gh repo create --template` and the "Use this template" button remain valid for
anyone who wants them; they are just not the path this flow documents.

## Consequences

- A second repo (`create-agent-workspace`) is maintained, loosely coupled to
  this one by the template's clone URL. The upside is a clean separation and no
  self-referential copying.
- The bootstrap is pinned to the template's default branch, not a tagged
  release. Workspaces are always scaffolded from the latest template. If that
  becomes a problem, the script can grow a `--ref` flag.
- Fetching a tarball means private templates would need auth; this template is
  public, so the simple path is fine.
