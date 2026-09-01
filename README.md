# dotfiles

Personal dotfiles managed with GNU Stow.

## Repo Layout

```text
dotfiles/
├── .stowrc                 # Stow target config (`~`)
├── agent-suite/            # Submodule: agents, skills, commands (not a Stow package)
├── claude/
│   └── .claude/            # Claude Code config; agents/skills/CLAUDE.md link into agent-suite/
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
- Starship (for the `starship` package)
- OpenCode (for the `opencode` package)
- Neovim (for the `neovim` package)
- Ghostty (for the `ghostty` package)
- tmux (for the `tmux` package)

## Install / Apply

Clone with the submodule, then stow from the repo root:

```bash
git clone --recurse-submodules git@github.com:crallen/dotfiles.git
# already cloned? git submodule update --init
stow claude ghostty neovim opencode starship tmux
```

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

## Common Maintenance

### Re-apply after adding, deleting, or renaming files

```bash
stow --restow <package>
```

Examples:

```bash
stow --restow claude
stow --restow ghostty
stow --restow neovim
stow --restow opencode
stow --restow starship
stow --restow tmux
```

### After editing existing symlinked files

Usually no restow is needed if the file is already symlinked. Reload the affected app instead.

## What lives here

### `claude`

The Claude Code config (`~/.claude/`):

- `agents/`, `skills/`, `CLAUDE.md` — symlinks into
  [agent-suite](https://github.com/crallen/agent-suite); edit them there
- `output-styles/` — alternate response styles selectable with `/output-style`
- `settings.json` — Claude Code runtime settings

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
- Add/remove/rename files in a Stow package usually means running `stow --restow <package>`.
- Editing an already-symlinked file usually just requires reloading the relevant app.

## License

[MIT](LICENSE)
