---
name: update-workspace
description: Refresh the agent workspace so nothing goes stale — update git submodules, sync agent skills, and update project dependencies. Use when the user asks to update, refresh, or unstale the workspace/submodules/deps/skills.
---

# Keep the workspace up to date

Submodules, external skills, and dependencies all drift over time. This skill
brings everything current.

## Full refresh

From the workspace root:

```bash
make update            # = update-submodules + update-agent-deps + update-agent-skills
```

Or run the pieces individually:

| Goal | Command | What it does |
| --- | --- | --- |
| Submodules stale | `make update-submodules` | `git submodule update --remote` on all, then re-syncs the VS Code workspace folders. |
| Skills stale | `make update-agent-skills` | Clones/fast-forwards every repo in `.agents/skills.manifest`. |
| Dependencies stale | `make update-agent-deps` | Detects the package manager per submodule and updates deps. |

## Procedure

1. Run `make update-submodules`. This moves each submodule to the latest
   remote commit on its tracked branch. Review the pointer changes:
   ```bash
   git submodule status
   git add -p        # stage the pointer bumps you want to keep
   ```
2. Run `make update-agent-deps` to bring dependencies current inside each
   submodule. Inspect and commit lockfile changes *inside each submodule*.
3. Run `make update-agent-skills` to sync external skills from the manifest.
4. Commit the parent-repo pointer bumps with a clear message, e.g.
   `chore: bump submodules & deps`.

## Rules

- Dependency and code changes belong to the submodule's own repo — commit them
  there first, then record the new pointer in the parent.
- Never hand-edit the `.code-workspace` folder list; `update-submodules`
  regenerates it via `make sync-workspace`.
- If something won't fast-forward, stop and inspect rather than forcing it.
