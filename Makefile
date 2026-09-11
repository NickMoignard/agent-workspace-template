# Agent workspace management.
# Run `make help` (or just `make`) to list targets.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Onboarding
# ---------------------------------------------------------------------------

.PHONY: setup
setup: ## One-time onboarding after cloning (submodules, pointers, beads, deps)
	@bash scripts/setup.sh

.PHONY: onboard
onboard: setup ## Alias for `setup`

# ---------------------------------------------------------------------------
# Keeping the workspace fresh
# ---------------------------------------------------------------------------

.PHONY: update-submodules
update-submodules: ## Pull every submodule to the latest remote commit on its tracked branch
	@echo "==> Updating all submodules to latest remote…"
	@git submodule update --init --recursive --remote
	@$(MAKE) --no-print-directory sync-workspace
	@echo "==> Submodules updated. Review & commit the new pointers with: git add -p"

.PHONY: update-agent-skills
update-agent-skills: ## Sync external agent skills from .agents/skills.manifest
	@bash scripts/update-agent-skills.sh

.PHONY: update-agent-deps
update-agent-deps: ## Update project dependencies (npm/pnpm/yarn/pip/poetry/go/cargo) in each submodule
	@bash scripts/update-agent-deps.sh

.PHONY: update
update: update-submodules update-agent-deps update-agent-skills ## Run all three update targets

# ---------------------------------------------------------------------------
# Submodule + workspace management
# ---------------------------------------------------------------------------

.PHONY: add-submodule
add-submodule: ## Add a project submodule: make add-submodule URL=<git-url> [DIR=<folder>] [BRANCH=<branch>]
	@bash scripts/add-submodule.sh "$(URL)" "$(DIR)" "$(BRANCH)"

.PHONY: sync-workspace
sync-workspace: ## Regenerate the *.code-workspace folder list from .gitmodules
	@node scripts/sync-workspace.mjs

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
	@echo "Example: make add-submodule URL=git@github.com:acme/api.git DIR=api"
