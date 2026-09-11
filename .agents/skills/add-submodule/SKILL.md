---
name: add-submodule
description: Add a new project to the agent workspace as a git submodule and wire it into the VS Code workspace and issue tracker. Use when the user wants to add, include, or pull a repo/project into the workspace.
---

# Add a submodule to the workspace

Use this when a new project should join the workspace as a git submodule.

## Procedure

1. **Gather inputs.** You need the git URL. Optionally a target directory
   (defaults to the repo name) and a branch to track.

2. **Run the make target** from the workspace root:

   ```bash
   make add-submodule URL=<git-url> DIR=<folder> BRANCH=<branch>
   ```

   `DIR` and `BRANCH` are optional. This wraps `scripts/add-submodule.sh`, which:
   - runs `git submodule add` and initializes it recursively,
   - regenerates the `*.code-workspace` folder list (`sync-workspace.mjs`),
   - installs the submodule's dependencies if a manifest is present,
   - files a beads onboarding issue (if `bd` is installed).

3. **Verify** the submodule folder appears in the `.code-workspace` file's
   `folders` array and that the working tree checked out.

4. **Commit the parent-repo change** (submodules add three things to commit):

   ```bash
   git add .gitmodules <dir> *.code-workspace
   git commit -m "Add <dir> submodule"
   ```

## Rules

- Never edit the `folders` block of the `.code-workspace` by hand — always
  regenerate it with `make sync-workspace`.
- Work on the submodule's code from *inside* the submodule directory (its own
  git repo), then update the pointer in the parent repo.
- If `make` is unavailable, call `bash scripts/add-submodule.sh <url> <dir> <branch>` directly.

## Removing a submodule

```bash
git submodule deinit -f <dir>
git rm <dir>
rm -rf .git/modules/<dir>
make sync-workspace
```
