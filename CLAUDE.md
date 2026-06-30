# dotfiles

Personal dotfiles managed with **GNU Stow**. Read this before changing files here.

## How this repo is structured

Each top-level directory is a **Stow package**. Its internal layout mirrors the path
relative to the home directory, because `.stowrc` sets `--target=~`. Applying a package
symlinks its contents into `~`.

| Package | Symlinks to |
|---|---|
| `claude/.claude/*` | `~/.claude/*` |
| `ghostty/.config/ghostty/*` | `~/.config/ghostty/*` |
| `neovim/.config/nvim/*` | `~/.config/nvim/*` |
| `opencode/.config/opencode/*` | `~/.config/opencode/*` |
| `starship/.config/starship.toml` | `~/.config/starship.toml` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |

So a file at `<package>/<path>` is what lives at `~/<path>` once stowed. To add a new
config file, place it inside the matching package at the path it should occupy under `~`.

## Working here

- **Editing an already-symlinked file is live** — the change takes effect immediately,
  no restow needed (just reload the affected app).
- **Adding, deleting, or renaming files** in a package requires `stow --restow <package>`
  to update the symlinks.
- Files are edited **in this repo**, never through the `~` symlink targets.

## The `claude/` package is the live Claude Code config

`claude/.claude/` is symlinked to `~/.claude/`, so editing files here edits the active
Claude Code configuration. It holds a custom agent suite (`agents/`, `skills/`),
`settings.json`, and `claude/.claude/CLAUDE.md` — the suite's **global** operating
instructions (distinct from this repo-root file). When changing that package, follow its
own conventions in `claude/.claude/skills/agent-authoring/`.

## Conventions

- Commits use Conventional Commits, scoped by package name (e.g. `docs(readme): ...`,
  `feat(claude): ...`, `chore(tmux): ...`). Repo-root files like this one and `README.md`
  use a descriptive scope such as `readme`, not a package scope.
- Never read or commit secret-bearing files (`.env`, keys, credentials).
- Keep `README.md` in sync when adding, removing, or renaming a package.
