# dotfiles

Personal dotfiles managed with GNU Stow.

## Repo Layout

```text
dotfiles/
├── .stowrc                 # Stow target config (`~`)
├── Makefile                # install / check / relink / update / status
├── scripts/links.py        # Owns the suite symlink manifest; --relink repairs it
├── agent-suite/            # Submodule: agents, skills, commands (not a Stow package)
├── claude/
│   └── .claude/            # Claude Code config; agents/skills/commands link into agent-suite/
├── codex/
│   └── .codex/             # Codex AGENTS.md + skills; all link into agent-suite/
├── ghostty/
│   └── .config/ghostty/    # Ghostty terminal config
├── neovim/
│   └── .config/nvim/       # LazyVim-based Neovim config
├── opencode/
│   └── .config/opencode/   # OpenCode config; agent/skills/commands link into agent-suite/
├── starship/
│   └── .config/starship.toml # Starship prompt config
├── tmux/
│   └── .tmux.conf          # tmux config
└── zsh/
    ├── .zshenv             # Env and PATH for every zsh process
    ├── .zshrc              # Interactive shell config
    └── .zsh_secrets.example # Seed for ~/.zsh_secrets (not stowed)
```

## Requirements

- GNU Stow
- Claude Code (for the `claude` package)
- Codex (for the `codex` package)
- Starship (for the `starship` package)
- OpenCode (for the `opencode` package)
- Neovim (for the `neovim` package)
- Ghostty (for the `ghostty` package)
- tmux (for the `tmux` package)
- zsh (for the `zsh` package); optionally fzf, zsh-autosuggestions, and
  zsh-syntax-highlighting, which it loads when installed

## Install / Apply

Clone with the submodule, then stow from the repo root:

```bash
git clone --recurse-submodules git@github.com:crallen/dotfiles.git
cd dotfiles && make install
```

`make install` checks out the submodule, seeds `claude/.claude/settings.json` and
`~/.zsh_secrets` from their examples when absent, and stows the packages this machine
wants, reporting any whose target already holds a real file. `make help` lists the rest;
`make check` verifies the suite symlinks and runs the suite's validator.

To stow only some packages on a given machine, list them in `packages.local` (one
per line). It is gitignored — it describes the machine, not the repo — and a
machine without one gets every package.

`agent-suite/` is a submodule, not a Stow package — it is never stowed directly. The
`claude` and `opencode` packages symlink into it, so the suite must be checked out
before stowing or those links dangle.

Because `.stowrc` sets `--target=~`, this will symlink:

- `claude/.claude/*` → `~/.claude/*`
- `ghostty/.config/ghostty/*` → `~/.config/ghostty/*`
- `neovim/.config/nvim/*` → `~/.config/nvim/*`
- `opencode/.config/opencode/*` → `~/.config/opencode/*`
- `starship/.config/starship.toml` → `~/.config/starship.toml`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `zsh/.zshenv`, `zsh/.zshrc` → `~/.zshenv`, `~/.zshrc`

## What lives here

### `claude`

The Claude Code config (`~/.claude/`):

- `agents/`, `skills/`, `commands/`, `CLAUDE.md` — symlinks into
  [agent-suite](https://github.com/crallen/agent-suite); edit them there
- `output-styles/` — alternate response styles selectable with `/output-style`
- `settings.json` — Claude Code runtime settings. **Gitignored and machine-local**;
  `make install` seeds it from `agent-suite/platforms/claude/settings.json.example`
  when absent, so a fresh machine never stows without the secret-file deny list

### `codex`

The Codex config (`~/.codex/`):

- `AGENTS.md` — Codex's own index of the suite; it has no named agent roster and
  invokes skills as `$name`, so it gets a document shaped for that rather than a
  copy of the Claude one
- `skills/` — one symlink per shared skill, into
  [agent-suite](https://github.com/crallen/agent-suite); edit them there

Skills are linked individually rather than as a whole directory, because Codex owns
`~/.codex/skills` and keeps its bundled `.system` set there. `config.toml` is
deliberately not stowed — Codex rewrites it at runtime.

### `ghostty`

- terminal font/theme/transparency settings

### `neovim`

- minimal LazyVim-based Neovim bootstrap/config

### `opencode`

The OpenCode config (`~/.config/opencode/`):

- `agent/`, `commands/`, `skills/`, `AGENTS.md` — symlinks into
  [agent-suite](https://github.com/crallen/agent-suite); edit them there
- `themes/` — custom UI themes
- `opencode.json` — runtime config and permissions
- `tui.json` — UI preferences

### `starship`

- minimal prompt config showing directory + git info
- cloud-profile modules disabled by default (`aws`, `gcloud`, `azure`)

### `tmux`

- terminal multiplexer config (`~/.tmux.conf`)

### `zsh`

The zsh config, split by which shells read it:

- `.zshenv` — read by every zsh process, scripts included, so it holds only cheap
  environment: `LANG`, `EDITOR`/`VISUAL` (nvim), `BUN_INSTALL`, and a deduplicated
  PATH that prepends `~/.local/bin`, `~/.bun/bin`, and `~/.opencode/bin` when they exist
- `.zshrc` — interactive shells only: options, a 100k-entry shared history in
  `~/.zsh_history`, completion, emacs key bindings, `ls`/`ll`/`grep` aliases, the
  plugins, secrets, and the starship prompt (a plain `%~ %#` prompt without it)
- `.zsh_secrets.example` — the commented template `make install` copies to
  `~/.zsh_secrets`; `.stow-local-ignore` keeps it out of `~`

Plugins come from distro packages, not a plugin manager. zsh-autosuggestions,
zsh-syntax-highlighting, and fzf key bindings each load when their files exist and are
skipped silently when not. fzf 0.48 or newer uses `fzf --zsh`; older versions, such as
the ones some distros package, fall back to the packaged `key-bindings.zsh`.

Machine-specific config goes in `~/.zshenv.local` and `~/.zshrc.local`, sourced last by
the matching file when present. Things like nvm, `NODE_OPTIONS`, or flyctl's PATH belong
there, not in the baseline. Both are gitignored so they never land in the package.

**Secrets.** `make install` seeds `~/.zsh_secrets` from the example with mode 600 when
the `zsh` package is selected and the file does not exist yet. `.zshrc` sources it only
when it is a regular file you own with no group or other permission bits; otherwise it
prints a warning asking for `chmod 600` and skips it. Only interactive shells load it, so
shells with no interactive ancestor (cron, systemd, `ssh host cmd`) never see these
values. Every value it exports still reaches every child process of an interactive
shell, scripts and agent-spawned shells included. Keep high-value,
project-scoped tokens in a gitignored `.envrc` or a password manager instead.

**Completions.** `compinit` reuses its dump at `~/.cache/zsh/zcompdump` (under
`$XDG_CACHE_HOME` when set) while it is under 24 hours old. After installing new
completions, run `rm ~/.cache/zsh/zcompdump` and open a new shell, or wait up to a day
for the rebuild.

**First stow.** A machine with its own `~/.zshrc` or `~/.zshenv` makes `make install`
report a conflict for `zsh`. Move them aside and carry the machine-specific parts into
the `.local` files:

```bash
[ -e ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.pre-stow
[ -e ~/.zshenv ] && mv ~/.zshenv ~/.zshenv.pre-stow
make install
```

Suggested packages:

- Arch: `pacman -S zsh zsh-autosuggestions zsh-syntax-highlighting fzf starship`
- Debian/Ubuntu: `apt install zsh zsh-autosuggestions zsh-syntax-highlighting fzf`,
  plus starship from its install script at <https://starship.rs>

## Acknowledgments

The agent suite's attribution lives with the suite, in
[agent-suite](https://github.com/crallen/agent-suite).

## Notes

- This repo is optimized for my own workflow, so documentation is intentionally practical rather than exhaustive.
- Editing an already-symlinked file is live — reload the affected app, nothing else.
- Adding, deleting, or renaming a file in a package needs `stow --restow <package>`.
- Suite content is the exception: skills and commands reach `claude` and `opencode`
  through a single whole-directory link, so anything added upstream is already live.
  `codex` links each skill individually, so a newly shared one needs `make relink`.

## License

[MIT](LICENSE)
