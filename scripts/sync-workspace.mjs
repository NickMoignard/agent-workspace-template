#!/usr/bin/env node
// Regenerate the "folders" list in the *.code-workspace file by scanning
// projects/.
//
// Every symlink under projects/ becomes a top-level folder in the VS Code
// multi-root workspace, plus the workspace root itself. Run via
// `make sync-workspace` (also called automatically by `make add-project` /
// `make sync-projects` / `make update-projects`).
//
// Idempotent: safe to run any time. Preserves "settings", "extensions", and any
// other top-level keys in the workspace file.

import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { basename, join } from "node:path";

const root = process.cwd();

function findWorkspaceFile() {
  const match = readdirSync(root).find((f) => f.endsWith(".code-workspace"));
  if (!match) {
    console.error("No *.code-workspace file found in", root);
    process.exit(1);
  }
  return join(root, match);
}

// Scan projects/ for referenced projects (symlinks into $AGENTS_GIT_SRC_DIR).
// Also tolerates real directories; ignores README.md and dotfiles.
function projectPaths() {
  let entries;
  try {
    entries = readdirSync(join(root, "projects"), { withFileTypes: true });
  } catch {
    return []; // no projects/ dir yet
  }
  return entries
    .filter((d) => !d.name.startsWith(".") && d.name !== "README.md")
    .filter((d) => d.isSymbolicLink() || d.isDirectory())
    .map((d) => `projects/${d.name}`)
    .sort();
}

function buildFolders(paths) {
  const entries = [
    { name: "⚙︎ workspace-root", path: "." },
    ...paths.map((p) => ({ name: basename(p), path: p })),
  ];
  // Two-space indent inside the "folders": [ … ] array.
  const body = entries
    .map((e) => `    {\n      "name": ${JSON.stringify(e.name)},\n      "path": ${JSON.stringify(e.path)}\n    }`)
    .join(",\n");
  return `"folders": [\n${body}\n  ]`;
}

const wsFile = findWorkspaceFile();
const original = readFileSync(wsFile, "utf8");
const paths = projectPaths();

// Replace the whole "folders": [ ... ] block (including any inline comments).
const foldersRe = /"folders"\s*:\s*\[[\s\S]*?\n\s*\]/;
if (!foldersRe.test(original)) {
  console.error('Could not locate a "folders": [ ... ] block in', wsFile);
  process.exit(1);
}
const updated = original.replace(foldersRe, buildFolders(paths));

if (updated !== original) {
  writeFileSync(wsFile, updated);
  console.log(`sync-workspace: wrote ${paths.length} project folder(s) to ${wsFile.replace(root + "/", "")}`);
} else {
  console.log("sync-workspace: already up to date");
}
