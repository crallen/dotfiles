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
└── tmux/
    └── .tmux.conf          # tmux config
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

## Install / Apply

Clone with the submodule, then stow from the repo root:

```bash
git clone --recurse-submodules git@github.com:crallen/dotfiles.git
cd dotfiles && make install
```

`make install` checks out the submodule and stows the packages this machine wants,
reporting any whose target already holds a real file. `make help` lists the rest;
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

## What lives here

### `claude`

The Claude Code config (`~/.claude/`):

- `agents/`, `skills/`, `commands/`, `CLAUDE.md` — symlinks into
  [agent-suite](https://github.com/crallen/agent-suite); edit them there
- `output-styles/` — alternate response styles selectable with `/output-style`
- `settings.json` — Claude Code runtime settings

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
