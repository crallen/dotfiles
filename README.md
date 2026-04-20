# dotfiles

Personal dotfiles managed with GNU Stow.

## Repo Layout

```text
dotfiles/
├── .stowrc                 # Stow target config (`~`)
├── ghostty/
│   └── .config/ghostty/    # Ghostty terminal config
├── neovim/
│   └── .config/nvim/       # LazyVim-based Neovim config
├── opencode/
│   └── .config/opencode/   # OpenCode agents, skills, commands, and config
└── starship/
    └── .config/starship.toml # Starship prompt config
```

## Requirements

- GNU Stow
- Starship (for the `starship` package)
- OpenCode (for the `opencode` package)
- Neovim (for the `neovim` package)
- Ghostty (for the `ghostty` package)

## Install / Apply

From the repo root:

```bash
stow ghostty neovim opencode starship
```

Because `.stowrc` sets `--target=~`, this will symlink:

- `ghostty/.config/ghostty/*` → `~/.config/ghostty/*`
- `neovim/.config/nvim/*` → `~/.config/nvim/*`
- `opencode/.config/opencode/*` → `~/.config/opencode/*`
- `starship/.config/starship.toml` → `~/.config/starship.toml`

## Common Maintenance

### Re-apply after adding, deleting, or renaming files

```bash
stow --restow <package>
```

Examples:

```bash
stow --restow ghostty
stow --restow neovim
stow --restow opencode
stow --restow starship
```

### After editing existing symlinked files

Usually no restow is needed if the file is already symlinked. Reload the affected app instead.

## What lives here

### `ghostty`

- terminal font/theme/transparency settings

### `neovim`

- minimal LazyVim-based Neovim bootstrap/config

### `opencode`

The OpenCode config currently includes:

- `agent/` — primary and specialist agent definitions
- `commands/` — slash command routing prompts
- `skills/` — reusable skill/reference material
- `AGENTS.md` — suite overview and usage guidance
- `opencode.json` — runtime config and permissions
- `tui.json` — UI preferences

### `starship`

- minimal prompt config showing directory + git info
- cloud-profile modules disabled by default (`aws`, `gcloud`, `azure`)

## Notes

- This repo is optimized for my own workflow, so documentation is intentionally practical rather than exhaustive.
- Add/remove/rename files in a Stow package usually means running `stow --restow <package>`.
- Editing an already-symlinked file usually just requires reloading the relevant app.
