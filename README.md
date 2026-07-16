# dotfiles

Personal dotfiles managed with GNU Stow.

## Repo Layout

```text
dotfiles/
├── .stowrc                 # Stow target config (`~`)
├── claude/
│   └── .claude/            # Claude Code agent suite (agents, skills, CLAUDE.md, settings)
├── ghostty/
│   └── .config/ghostty/    # Ghostty terminal config
├── neovim/
│   └── .config/nvim/       # LazyVim-based Neovim config
├── opencode/
│   └── .config/opencode/   # OpenCode agents, skills, commands, and config
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

From the repo root:

```bash
stow claude ghostty neovim opencode starship tmux
```

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

The Claude Code config (`~/.claude/`) — a custom suite of software-engineering agents, skills, and slash commands:

- `agents/` — specialist subagent definitions (code review, security, testing, debugging, frontend/backend, etc.)
- `skills/` — reference skills plus user-invocable workflow skills (the `/`-commands)
- `CLAUDE.md` — suite overview and tech-lead operating instructions
- `settings.json` — Claude Code runtime settings

### `ghostty`

- terminal font/theme/transparency settings

### `neovim`

- minimal LazyVim-based Neovim bootstrap/config

### `opencode`

The OpenCode config currently includes:

- `agent/` — primary and specialist agent definitions
- `commands/` — slash command routing prompts
- `skills/` — reusable skill/reference material
- `themes/` — custom UI themes
- `AGENTS.md` — suite overview and usage guidance
- `opencode.json` — runtime config and permissions
- `tui.json` — UI preferences

### `starship`

- minimal prompt config showing directory + git info
- cloud-profile modules disabled by default (`aws`, `gcloud`, `azure`)

### `tmux`

- terminal multiplexer config (`~/.tmux.conf`)

## Acknowledgments

The Claude Code and OpenCode agent suites draw inspiration from Matt Pocock's
[skills](https://github.com/mattpocock/skills) repo — the `skill-design` and
`code-review-checklist` skills adapt material from it directly.

## Notes

- This repo is optimized for my own workflow, so documentation is intentionally practical rather than exhaustive.
- Add/remove/rename files in a Stow package usually means running `stow --restow <package>`.
- Editing an already-symlinked file usually just requires reloading the relevant app.
