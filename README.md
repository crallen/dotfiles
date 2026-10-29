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
├── t3code/
│   ├── .local/bin/t3-serve # Start script for the T3 Code server
│   └── .config/systemd/user/t3-serve.service # systemd user unit that runs it
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
- For the `t3code` package: node and npx, from nvm or anywhere else on PATH; the
  agent CLIs (`claude`, `codex`) in `~/.local/bin`; a systemd user session. The
  `zsh` package supplies the PATH the start script reads
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
wants, reporting any whose target already holds a real file. When `t3code` is among
them, it then enables and starts the `t3-serve` user service. `make help` lists the rest;
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
- `t3code/.local/bin/t3-serve` → `~/.local/bin/t3-serve`
- `t3code/.config/systemd/user/t3-serve.service` → `~/.config/systemd/user/t3-serve.service`
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

### `t3code`

Runs the [T3 Code](https://github.com/pingdotgg/t3code) server as a systemd user
service:

- `.local/bin/t3-serve` — zsh start script that runs
  `npx --yes t3@latest serve --host 127.0.0.1 --port 3773`. The server binds loopback
  only, so the port is never exposed on the network
- `.config/systemd/user/t3-serve.service` — the unit that runs the script. It waits
  for `network-online.target` and restarts on failure after 5 seconds

**PATH.** The script sets no PATH of its own. It is a zsh script, so zsh reads
`~/.zshenv` before running it. The baseline puts `~/.local/bin` (where `claude` and
`codex` live) and the newest installed nvm node on PATH. A machine that needs a
different node prepends it in `~/.zshenv.local`:

```zsh
path=(~/.nvm/versions/node/v22.22.2/bin $path)
```

With no node on PATH, `npx` is not found and the unit fails and retries every 5
seconds. Secrets never reach the server, because zsh reads `.zshrc` only for
interactive shells.

**Linger.** A user service stops at logout unless linger is on:

```bash
sudo loginctl enable-linger "$USER"
```

**Install.** After stowing, `make install` runs `systemctl --user daemon-reload` and
`systemctl --user enable --now t3-serve.service`, then warns if linger is off. It
starts a stopped server but never restarts a running one, so edits to the script or
unit take effect on the next restart.

**Operations.**

```bash
systemctl --user restart t3-serve     # also picks up a new t3 release
systemctl --user status t3-serve
journalctl --user -u t3-serve -f      # follow logs
```

The script runs `t3@latest`, so every start resolves the newest release from npm.

**First stow.** A machine that already has `~/.config/systemd/user/t3-serve.service`,
such as a symlink from an earlier install, makes `make install` report a conflict for
`t3code`. Remove it first:

```bash
rm ~/.config/systemd/user/t3-serve.service
make install
```

**Remote access.** The T3 Code app on a laptop connects over SSH and attaches to the
running server on port 3773. A phone or browser needs one of these:

- Tailscale: `npx t3@latest pair --tailscale` publishes the server over Tailscale
  Serve on the tailnet and pairs the device against that origin
- T3 Connect: `npx t3@latest connect login --headless` authorizes the host against
  your account, then `npx t3@latest connect link` exposes it through the T3 relay.
  `npx t3@latest connect publish` turns on push notifications, which `connect link`
  alone does not

### `tmux`

- terminal multiplexer config (`~/.tmux.conf`)

### `zsh`

The zsh config, split by which shells read it:

- `.zshenv` — read by every zsh process, scripts included, so it holds only cheap
  environment: `LANG`, `EDITOR`/`VISUAL` (nvim), `BUN_INSTALL`, and a deduplicated
  PATH that prepends `~/.local/bin`, `~/.bun/bin`, and `~/.opencode/bin` when they
  exist, plus the bin directory of the newest node installed under `~/.nvm`
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
the matching file when present. Things like `NODE_OPTIONS` or flyctl's PATH belong
there, not in the baseline. The newest nvm node is on PATH from the baseline already,
so only loading `nvm.sh`, which interactive `nvm use` needs, belongs in
`~/.zshrc.local`. Both are gitignored so they never land in the package.

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
