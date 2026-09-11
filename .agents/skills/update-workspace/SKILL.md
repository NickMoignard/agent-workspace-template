---
name: update-workspace
description: Refresh the agent workspace so nothing goes stale — pull referenced projects, sync agent skills, and update project dependencies. Use when the user asks to update, refresh, or unstale the workspace/projects/deps/skills.
---

# Keep the workspace up to date

Referenced projects, external skills, and dependencies all drift over time. This
skill brings everything current.

## Full refresh

From the workspace root:

```bash
make update            # = update-projects + update-agent-deps + update-agent-skills
```

Or run the pieces individually:

| Goal | Command | What it does |
| --- | --- | --- |
| Projects stale | `make update-projects` | `git pull --ff-only` in each linked project's clone, then re-syncs the VS Code workspace folders. |
| Skills stale | `make update-agent-skills` | Runs `npx skills update` to refresh external skills tracked in `skills-lock.json`. |
| Dependencies stale | `make update-agent-deps` | Detects the package manager per project and updates deps. |

## Procedure

1. Run `make update-projects`. This fast-forwards each linked project's clone to
   the latest commit on its default branch. Nothing to commit in the workspace —
   it pins no project commits. If a project needs a new project added or linked,
   use `make add-project URL=<git-url>` (or `make sync-projects` after editing
   `projects.yaml`).
2. Run `make update-agent-deps` to bring dependencies current inside each
   project. Inspect and commit lockfile changes *inside each project's own repo*.
3. Run `make update-agent-skills` to refresh external skills (via `npx skills
   update`). Add new ones with `npx skills@latest add <owner/repo> -a universal`,
   then commit `.agents/skills/` + `skills-lock.json`.
4. Commit any workspace-level changes (e.g. `projects.yaml`) with a clear message.

## Rules

- Dependency and code changes belong to the project's own repo — commit them
  there. The workspace tracks only its own config (`projects.yaml`, skills).
- Never hand-edit the `.code-workspace` folder list; `update-projects` and
  `sync-projects` regenerate it via `make sync-workspace`.
- If something won't fast-forward, stop and inspect rather than forcing it.
