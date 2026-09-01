# dotfiles — GNU Stow packages plus the agent-suite submodule.
#
# The packages hold no suite content: every agent, skill, command, and index
# document is a symlink into agent-suite/. `make check` is the target that earns
# its keep — a skill shared to codex upstream needs a matching link here, and the
# suite's own validator cannot see this repo.

# Every package in the repo. A machine that wants only some of them writes those
# names into packages.local (gitignored, one line or one per line); machines with
# no such file get everything. Override for a single run with `make PACKAGES=...`.
ALL      := claude codex ghostty neovim opencode starship tmux
PACKAGES ?= $(shell cat packages.local 2>/dev/null || echo $(ALL))
SUITE    := agent-suite

# The packages holding links into the suite. Adding a top-level entry to one of
# these (a commands/ directory, a codex skill) needs a restow before it reaches
# ~, because stow links per entry wherever a real directory already sits at the
# target. Restowing one already stowed is a no-op, so relink covers all three.
SUITE_PKGS := claude codex opencode

.DEFAULT_GOAL := help
.PHONY: help install check suite-check relink update status

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk -F':.*?## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

install: ## Check out the submodule and stow every package
	@git submodule update --init --recursive
	@failed=""; for p in $(PACKAGES); do \
	  if stow "$$p" 2>/dev/null; then echo "  stowed    $$p"; \
	  else echo "  CONFLICT  $$p"; failed="$$failed $$p"; fi; \
	done; \
	if [ -n "$$failed" ]; then \
	  echo; echo "A real file sits at the target for:$$failed"; \
	  echo "Inspect with 'stow -n <package>', then move the file aside or skip the package."; \
	  exit 1; \
	fi

check: ## Verify every suite link, then run the suite's own validator
	@scripts/links.py
	@echo
	@$(MAKE) --no-print-directory suite-check

suite-check:
	@if [ -x $(SUITE)/scripts/validate-config.py ]; then \
	  cd $(SUITE) && scripts/validate-config.py -q; \
	else \
	  echo "$(SUITE) is not checked out — run 'make install'"; exit 1; \
	fi

relink: ## Repair the suite links, then restow so they reach ~
	@scripts/links.py --relink
	@for p in $(SUITE_PKGS); do \
	  case " $(PACKAGES) " in *" $$p "*) ;; *) continue ;; esac; \
	  if stow --restow "$$p" 2>/dev/null; then echo "  restowed  $$p"; \
	  else echo "  CONFLICT  $$p — inspect with 'stow -n --restow $$p'"; fi; \
	done

update: ## Pull the latest agent-suite, relink, and show the pointer to commit
	@git submodule update --remote --merge $(SUITE)
	@$(MAKE) --no-print-directory relink
	@echo
	@if git diff --quiet -- $(SUITE); then \
	  echo "agent-suite pointer unchanged."; \
	else \
	  git diff --submodule=short -- $(SUITE); \
	  echo "Commit it with: git add $(SUITE) && git commit -m 'chore($(SUITE)): bump'"; \
	fi

status: ## Show which packages are stowed, and which this machine skips
	@for p in $(ALL); do \
	  case " $(PACKAGES) " in *" $$p "*) ;; *) printf "  %-10s %s\n" "$$p" "skipped here"; continue ;; esac; \
	  out=$$(stow -n -v "$$p" 2>&1); \
	  if echo "$$out" | grep -q 'WARNING! stowing'; then s="conflict"; \
	  elif echo "$$out" | grep -q '^LINK:'; then s="not stowed"; \
	  else s="stowed"; fi; \
	  printf "  %-10s %s\n" "$$p" "$$s"; \
	done
