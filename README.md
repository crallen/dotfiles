# dotfiles

Personal dotfiles managed with GNU Stow. Right now this repo mainly contains the local OpenCode configuration.

## Repo Layout

```text
dotfiles/
├── .stowrc                 # Stow target config (`~`)
└── opencode/
    └── .config/opencode/   # OpenCode agents, skills, commands, and config
```

## Requirements

- GNU Stow
- OpenCode

## Install / Apply

From the repo root:

```bash
stow opencode
```

Because `.stowrc` sets `--target=~`, this will symlink:

- `opencode/.config/opencode/*` → `~/.config/opencode/*`

## Common Maintenance

### Re-apply after adding, deleting, or renaming files

```bash
stow --restow opencode
```

### After editing existing OpenCode files

Usually no restow is needed if the file is already symlinked. Just reload/restart OpenCode.

## What lives here

The OpenCode config currently includes:

- `agent/` — primary and specialist agent definitions
- `commands/` — slash command routing prompts
- `skills/` — reusable skill/reference material
- `AGENTS.md` — suite overview and usage guidance
- `opencode.json` — runtime config and permissions
- `tui.json` — UI preferences

## Notes

- This repo is optimized for my own workflow, so documentation is intentionally practical rather than exhaustive.
- If more dotfiles get added later, this README should expand to document each Stow package and any machine-specific setup.
