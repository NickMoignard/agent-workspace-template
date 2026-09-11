# 1. Agent-first task execution, mechanical Makefile underneath

Date: 2026-09-11

## Status

Accepted

## Context

An agent workspace is harness-agnostic by design (see `AGENTS.md`): instructions
live in `AGENTS.md`/`.agents/`, and harness-specific files are only pointers.

Setup and maintenance tasks fall into two shapes:

- **Deterministic, single-step** work — clone and symlink the manifest's
  projects (see ADR 0004), sync the VS Code workspace, initialize the beads
  database. A shell script does this perfectly.
- **Multi-step, environment-adaptive** work — e.g. installing `asdf`, adding
  plugins, wiring shims onto `PATH` across different shells/OSes, then running
  `asdf install`. Each step depends on the previous one's outcome and on the
  machine's current state. Encoding every branch in portable shell is brittle;
  when it breaks, a human is left debugging shell.

We considered having `make setup` invoke `claude --prompt "/setup-asdf …"`
directly. That was rejected: baking one harness (`claude`) into the most
fundamental onboarding command contradicts the harness-agnostic principle and
breaks for users on Cursor, Codex, Aider, or with no CLI installed.

## Decision

We split responsibilities into two layers:

1. **Mechanical layer — Makefile + `scripts/`.** Deterministic and
   harness-agnostic. Never invokes an AI harness. Safe for anyone to run.
2. **Agent layer — skills in `.agents/skills/`.** Multi-step, adaptive
   procedures live here as skills (e.g. `setup-asdf`). An agent executes them,
   because an agent can inspect state, adapt across environments, and debug
   failures mid-procedure far better than a fixed script or a human following
   instructions.

**Invocation of the agent layer is the user's choice**, documented in
`README.md` with example commands for multiple harnesses (`claude`, `codex`).
The Makefile never calls a harness itself.

We lean on the agent layer as the *default* way to perform workspace tasks: it
lets an agent — not the user — own multi-step processes and their debugging.

## Consequences

- `make setup` stays runnable everywhere, with zero harness dependency.
- Complex, stateful setup (asdf, toolchains) is owned by skills an agent runs;
  failures are debugged by the agent, not the user.
- Some capability is documented as agent-invoked prompts rather than a single
  `make` target — users pick their harness. README must keep these commands
  current for each supported harness.
- Skills and mechanical scripts can overlap; when they do, the skill is the
  richer, adaptive path and the script is the dumb, guaranteed one.
