---
name: add-project
description: Add a new project to the agent workspace by recording its clone URL in projects.yaml, cloning it into the shared source dir, and symlinking it into projects/. Wires it into the VS Code workspace and issue tracker. Use when the user wants to add, include, or pull a repo/project into the workspace.
---

# Add a project to the workspace

Use this when a new project should join the workspace. Projects are referenced
as symlinks to shared clones, not git submodules (see
`docs/adr/0004-projects-as-symlinks-not-submodules.md`).

## Procedure

1. **Gather inputs.** You need the git clone URL. The symlink name is derived
   from the repo basename automatically.

2. **Confirm prerequisites.** `$AGENTS_GIT_SRC_DIR` must be set and `yq` present.
   If the env var is unset, run `/setup-projects` first.

3. **Run the make target** from the workspace root:

   ```bash
   make add-project URL=<git-url>
   ```

   This wraps `scripts/add-project.sh`, which:
   - appends the URL to `projects.yaml` (if not already listed),
   - clones it into `$AGENTS_GIT_SRC_DIR/<name>` and symlinks `projects/<name>`,
   - regenerates the `*.code-workspace` folder list (`sync-workspace.mjs`),
   - installs the project's dependencies if a manifest is present,
   - files a beads onboarding issue (if `bd` is installed).

4. **Verify** the project's folder appears in the `.code-workspace` `folders`
   array and `projects/<name>` resolves to the clone.

5. **Commit the workspace change** (the symlink is git-ignored — do not add it):

   ```bash
   git add projects.yaml workspace.code-workspace
   git commit -m "Add <name> project"
   ```

## Rules

- Never edit the `folders` block of the `.code-workspace` by hand — always
  regenerate it with `make sync-workspace`.
- Work on the project's code from *inside* its clone (its own git repo). The
  workspace pins no commits; there is no parent pointer to update.
- If `make` is unavailable, call `bash scripts/add-project.sh <url>` directly.

## Removing a project

```bash
# 1. Remove the URL line from projects.yaml (edit, or with yq):
yq -i 'del(.projects[] | select(. == "<git-url>"))' projects.yaml
# 2. Drop the symlink (leaves the shared clone intact for other workspaces):
rm -f projects/<name>
# 3. Refresh the VS Code folders:
make sync-workspace
```
