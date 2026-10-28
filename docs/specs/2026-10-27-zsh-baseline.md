# zsh baseline package

## Goal

Add a `zsh` stow package holding a baseline `.zshenv` and `.zshrc` that serves the new
FSG server, this machine, and the WSL box. Secrets live in an untracked, mode-600
`~/.zsh_secrets` loaded only by interactive shells; per-machine differences live in
`~/.zshenv.local` and `~/.zshrc.local`.

## Context

- Current `~/.zshrc` (19 lines): starship, uv's `~/.local/bin/env`, opencode PATH, eager
  nvm, bun completion + PATH, `LANG` set twice. No history, completion, or key config.
- Current `~/.zshenv`: one line, `LANG`. Both are real files, so the first stow conflicts;
  `make install` already reports conflicts.
- The WSL `.zshrc` has the same shape: history opts, bare `compinit`, `ls`/`ll` aliases,
  secrets sourced from `~/.zsh_secrets`, `NODE_OPTIONS=--use-system-ca`, flyctl, nvm, bun.
  Its machine-specific parts (`NODE_OPTIONS`, `FLYCTL_INSTALL`, nvm) belong in that box's
  `.local` files.
- Arch's `/etc/zsh/zprofile` sources `/etc/profile`, which appends system dirs to PATH
  (no reset). Debian's `/etc/zsh/zshenv` runs before `~/.zshenv`.
- Tooling on this machine: starship and gpg present; no fzf or zsh plugins installed yet.
- `make install` already seeds `claude/.claude/settings.json` from an example; the secrets
  seed copies that pattern. Packages opt in per machine via `packages.local`.

## Approach

Two flat files plus untracked local overrides. Split by purpose: `.zshenv` (every zsh
process) carries only cheap env and PATH; `.zshrc` (interactive) carries everything else,
including secrets, so non-interactive processes never receive them.

No plugin manager: distro-packaged plugins are sourced when their files exist. nvm stays
out of the baseline and lives in `~/.zshrc.local` where wanted.

Rejected: `ZDOTDIR=~/.config/zsh` with `conf.d` fragments (too much indirection for ~120
lines; installers appending to `~/.zshrc` would miss); plugin managers and oh-my-zsh
(network dependency, startup cost); encrypted or password-manager secrets (unlock flow
breaks headless SSH and agent shells).

## Components

### `zsh/.zshenv`

- `LANG=en_US.UTF-8`, `EDITOR=nvim`, `VISUAL=nvim`, `BUN_INSTALL=~/.bun`.
- `typeset -U path`; prepend only existing dirs via the `(N/)` qualifier: `~/.local/bin`,
  `~/.bun/bin`, `~/.opencode/bin`. Replaces sourcing uv's `env` script.
- Source `~/.zshenv.local` last if present.
- No secrets, no command substitutions.

### `zsh/.zshrc`

In order:

1. **Options**: `auto_cd`, `auto_pushd`, `pushd_ignore_dups`, `interactive_comments`,
   `extended_glob`, `no_beep`.
2. **History**: `HISTFILE=~/.zsh_history` (keeps existing history), `HISTSIZE=SAVEHIST=100000`;
   `extended_history`, `share_history`, `hist_ignore_all_dups`, `hist_ignore_space`,
   `hist_reduce_blanks`, `hist_find_no_dups`, `hist_save_no_dups`. Not `inc_append_history`
   or `append_history`: `share_history` already writes incrementally and the zsh docs advise
   against combining it with `inc_append_history`.
3. **Completion**: `autoload -Uz compinit`; dump at `${XDG_CACHE_HOME:-~/.cache}/zsh/zcompdump`
   (create the dir); `compinit -C` when the dump is under 24h old, full `compinit` otherwise.
   zstyles: `menu select`, case-insensitive `matcher-list`, `list-colors` from `LS_COLORS`.
4. **Keys**: `bindkey -e`; Up/Down bound to `up-line-or-beginning-search` /
   `down-line-or-beginning-search`; Home, End, Delete, Ctrl-Left/Right bound via
   `terminfo` so they work in tmux and over SSH from Ghostty.
5. **Aliases**: `ls="ls --color=auto"`, `ll="ls -lhFA"`, `grep="grep --color=auto"`.
6. **Plugins**, each sourced from the first existing path:
   - zsh-autosuggestions: `/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh`
     (Arch), `/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (Debian/Ubuntu).
   - fzf: `source <(fzf --zsh)` when fzf ≥ 0.48; otherwise `/usr/share/fzf/key-bindings.zsh`
     (Arch) or `/usr/share/doc/fzf/examples/key-bindings.zsh` (Debian/Ubuntu).
7. **Secrets**: `_load_secrets` sources `~/.zsh_secrets` only when it is a regular file
   owned by `$USER` with no group/other permission bits; otherwise prints one stderr
   warning naming the `chmod 600` fix and skips it. Never changes permissions itself.
8. **Prompt**: `eval "$(starship init zsh)"` when starship exists, else `PROMPT='%~ %# '`.
9. **`~/.zshrc.local`**: sourced if present.
10. **zsh-syntax-highlighting**: last, after `.local`, since it must follow all widget
    definitions. Paths: `/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`
    (Arch), `/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh` (Debian/Ubuntu).

### `zsh/.zsh_secrets.example` and `zsh/.stow-local-ignore`

The example is fully commented `export NAME=value` lines with a header: keep mode 600,
only interactive shells load it, prefix commands with a space to keep them out of
history. `.stow-local-ignore` excludes the example and itself so neither is stowed.

### `Makefile`

- Add `zsh` to `ALL`.
- New `seed-secrets` target: exits early unless `zsh` is in `PACKAGES`; if
  `~/.zsh_secrets` is absent, copies the example under `umask 077`; never overwrites.
- `install` calls it after `seed-settings`.

### `.gitignore`

Add `.zsh_secrets`, `.zshrc.local`, `.zshenv.local` as a guard against creating them
inside the package.

### `README.md` and `CLAUDE.md`

README: `zsh/` in the layout tree and symlink list, zsh in Requirements, and a `zsh`
section covering the files, `.local` overrides, secrets workflow, the exposure caveat,
the compdump note, and suggested packages:

- Arch: `pacman -S zsh zsh-autosuggestions zsh-syntax-highlighting fzf starship`
- Debian/Ubuntu: `apt install zsh zsh-autosuggestions zsh-syntax-highlighting fzf`, plus
  starship's install script.

CLAUDE.md: add the `zsh` row to the package table.

### agent-suite deny rule

Add `Read(~/.zsh_secrets)` to the deny list in
`agent-suite/platforms/claude/settings.json.example`, and the same rule to this machine's
`claude/.claude/settings.json` so `make check` stays green.

## Error Handling

- Missing starship, fzf, or plugins: skipped silently.
- Missing `~/.zsh_secrets`: skipped silently.
- `~/.zsh_secrets` with wider-than-600 permissions or wrong owner: not sourced; one line
  to stderr: `zsh: ~/.zsh_secrets not loaded: permissions must be 600 (chmod 600 ~/.zsh_secrets)`.
- Errors inside `.local` or secrets files: zsh reports them and continues loading.
- `seed-secrets` with the file present: no-op.
- Stow conflict with existing `~/.zshrc`/`~/.zshenv`: reported by `make install`; task 7
  migrates by hand.

## Testing

Run from a clean env (`env -i HOME=$HOME TERM=$TERM zsh …`) unless noted.

1. `zsh -n zsh/.zshenv zsh/.zshrc` passes.
2. `stow -n -v zsh` links only `.zshenv` and `.zshrc`.
3. `zsh -c 'print -l $path'` includes `~/.local/bin` (plus bun/opencode where present),
   with no duplicates.
4. With `export ZSH_SECRETS_PROBE=1` in `~/.zsh_secrets`:
   `zsh -i -c 'echo ${ZSH_SECRETS_PROBE-unset}'` prints `1`;
   `zsh -c 'echo ${ZSH_SECRETS_PROBE-unset}'` prints `unset`.
5. After `chmod 644 ~/.zsh_secrets`, the interactive shell prints the warning and the
   probe is `unset`; restore `chmod 600`.
6. `zsh -i -c exit` writes nothing to stderr, both with no plugins installed and with
   all installed.
7. `time zsh -i -c exit` without nvm stays under ~100 ms on this machine.
8. `make install` on a box without `~/.zsh_secrets` creates it with mode `600`
   (`stat -c %a`); a second run leaves it unchanged.
9. Manual: Up/Down prefix search, Home/End/Delete, Ctrl-Left/Right work inside tmux,
   locally and over SSH from Ghostty.

## Risks & Open Questions

- **Risk**: exported secrets reach every child process of an interactive shell, including
  agent-spawned shells. Inherent to a sourced plaintext file; the mode check and deny rule
  only guard the file itself. README points high-value, project-scoped tokens at a
  gitignored `.envrc` or a password manager.
- **Risk**: `compinit -C` can serve a stale dump for up to 24h after new completions are
  installed. README documents deleting the dump.
- **Risk**: `.stow-local-ignore` replaces stow's default ignore list for the package. The
  package holds no README or VCS files; Testing 2 verifies nothing extra is stowed.
- **Risk**: Debian/Ubuntu ship fzf older than 0.48; handled by the fallback path, and
  bindings are skipped if neither exists.

## Task Checklist

- [x] 1. Create `zsh/.zshenv` per Components: `LANG`, `EDITOR`/`VISUAL=nvim`,
  `BUN_INSTALL`, deduped `path` prepending only existing `~/.local/bin`, `~/.bun/bin`,
  `~/.opencode/bin`, then source `~/.zshenv.local` if present.
- [ ] 2. Create `zsh/.zshrc` with sections 1–10 in the order listed under Components,
  including `_load_secrets` and first-existing-path plugin lookup.
- [ ] 3. Create `zsh/.zsh_secrets.example` (fully commented, with header) and
  `zsh/.stow-local-ignore` excluding the example and itself.
- [ ] 4. Update `Makefile`: add `zsh` to `ALL`; add `seed-secrets` (gated on `zsh` in
  `PACKAGES`, `umask 077`, copy only when absent); call it from `install` after
  `seed-settings`. (blocked by 3)
- [x] 5. Update `.gitignore` with `.zsh_secrets`, `.zshrc.local`, `.zshenv.local`.
- [ ] 6. Update `README.md` (layout tree, symlink list, Requirements, `zsh` section with
  secrets workflow, exposure caveat, compdump note, Arch and Debian/Ubuntu package lines)
  and the package table in `CLAUDE.md`. (blocked by 1, 2, 3, 4)
- [ ] 7. Migrate this machine: move `~/.zshrc` and `~/.zshenv` to `*.pre-stow`; write
  `~/.zshrc.local` with nvm load and bun completion; add `zsh` to `packages.local`; run
  `make install`; run Testing 1–9. (blocked by 1, 2, 4)
- [x] 8. agent-suite: add `Read(~/.zsh_secrets)` to
  `platforms/claude/settings.json.example`'s deny list and run its validator; add the
  same rule to `claude/.claude/settings.json`; commit and push the suite, then bump the
  pointer.
