# Agent workspace management.
# Run `make help` (or just `make`) to list targets.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Onboarding
# ---------------------------------------------------------------------------

.PHONY: setup
setup: ## One-time onboarding after cloning (projects, pointers, beads, deps)
	@bash scripts/setup.sh

.PHONY: onboard
onboard: setup ## Alias for `setup`

# ---------------------------------------------------------------------------
# Keeping the workspace fresh
# ---------------------------------------------------------------------------

.PHONY: update-projects
update-projects: ## Pull every linked project to the latest commit on its default branch
	@echo "==> Updating linked projects…"
	@for p in projects/*/; do \
	  [ -e "$$p/.git" ] || continue; \
	  echo "  $$p"; git -C "$$p" pull --ff-only || echo "    (skipped: won't fast-forward)"; \
	done
	@$(MAKE) --no-print-directory sync-workspace
	@echo "==> Projects updated. Commit any lockfile changes inside each project's own repo."

.PHONY: update-agent-skills
update-agent-skills: ## Refresh external agent skills via `npx skills update` (tracked in skills-lock.json)
	@bash scripts/update-agent-skills.sh

.PHONY: update-agent-deps
update-agent-deps: ## Update project dependencies (npm/pnpm/yarn/pip/poetry/go/cargo) in each project
	@bash scripts/update-agent-deps.sh

.PHONY: update
update: update-projects update-agent-deps update-agent-skills ## Run all three update targets

# ---------------------------------------------------------------------------
# Project + workspace management
# ---------------------------------------------------------------------------

.PHONY: add-project
add-project: ## Add a project: make add-project URL=<git-url> (clones + symlinks + records in projects.yaml)
	@bash scripts/add-project.sh "$(URL)"

.PHONY: sync-projects
sync-projects: ## Clone+symlink every project in projects.yaml into projects/ (needs AGENTS_GIT_SRC_DIR)
	@bash scripts/sync-projects.sh

.PHONY: sync-workspace
sync-workspace: ## Regenerate the *.code-workspace folder list by scanning projects/
	@bash scripts/run-node.sh scripts/sync-workspace.mjs

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

.PHONY: help
help: ## Show this help
	@echo "Agent workspace — available targets:"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Example: make add-project URL=git@github.com:acme/api.git"
