# Projects

This folder holds one **symlink per referenced project**, each pointing at that
project's clone in the shared source directory:

```
projects/<name>  ->  $AGENTS_GIT_SRC_DIR/<name>
```

The symlinks (and the clones they point to) are **git-ignored** — they are
machine-specific absolute paths. Only this README and the top-level
`projects.yaml` manifest are committed. The workspace therefore stays
independent of the projects it references: it pins no commits and does not
track their history. See [`../docs/adr/0004-projects-as-symlinks-not-submodules.md`](../docs/adr/0004-projects-as-symlinks-not-submodules.md).

## How the links get here

- **`projects.yaml`** lists the clone URLs (default branch only, no pins).
- **`/setup-projects`** ensures `$AGENTS_GIT_SRC_DIR` exists (default
  `~/agents/git_repos`) and then runs the mechanical sync.
- **`make sync-projects`** (`scripts/sync-projects.sh`) clones any missing repo
  into the source dir and (re)creates the symlinks here.
- **`make add-project URL=<git-url>`** appends a URL to the manifest and links it.
- **`make sync-workspace`** rebuilds the VS Code folder list by scanning this
  directory.

Because clones are shared in `$AGENTS_GIT_SRC_DIR`, the same project can be
symlinked into several workspaces at once and edits are seen by all of them.
