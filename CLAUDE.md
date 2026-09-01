# dotfiles

Personal dotfiles managed with **GNU Stow**. Read this before changing files here.

## How this repo is structured

Each top-level directory is a **Stow package**. Its internal layout mirrors the path
relative to the home directory, because `.stowrc` sets `--target=~`. Applying a package
symlinks its contents into `~`.

| Package | Symlinks to |
|---|---|
| `claude/.claude/*` | `~/.claude/*` |
| `codex/.codex/skills/*` | `~/.codex/skills/*` |
| `ghostty/.config/ghostty/*` | `~/.config/ghostty/*` |
| `neovim/.config/nvim/*` | `~/.config/nvim/*` |
| `opencode/.config/opencode/*` | `~/.config/opencode/*` |
| `starship/.config/starship.toml` | `~/.config/starship.toml` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |

So a file at `<package>/<path>` is what lives at `~/<path>` once stowed. To add a new
config file, place it inside the matching package at the path it should occupy under `~`.

`agent-suite/` is **not** a Stow package. It is a git submodule, described below.

## Working here

- **Editing an already-symlinked file is live** — the change takes effect immediately,
  no restow needed (just reload the affected app).
- **Adding, deleting, or renaming files** in a package requires `stow --restow <package>`
  to update the symlinks — *except* below a package entry that is itself a symlink (every
  path in the table under "The agent suite is a submodule"). Stow links to those entries
  as single files and never descends, so anything added inside them is live immediately.
- Files are edited **in this repo**, never through the `~` symlink targets.

## The agent suite is a submodule

The agents, skills, and commands live in
[agent-suite](https://github.com/crallen/agent-suite), checked out at `agent-suite/`.
The two harness packages hold symlinks into it rather than real files:

| Package path | Submodule target |
|---|---|
| `claude/.claude/agents` | `agent-suite/agents` |
| `claude/.claude/skills` | `agent-suite/skills` |
| `claude/.claude/CLAUDE.md` | `agent-suite/AGENTS.md` |
| `opencode/.config/opencode/agent` | `agent-suite/platforms/opencode/agent` |
| `opencode/.config/opencode/commands` | `agent-suite/platforms/opencode/commands` |
| `opencode/.config/opencode/skills` | `agent-suite/platforms/opencode/skills` |
| `opencode/.config/opencode/AGENTS.md` | `agent-suite/platforms/opencode/AGENTS.md` |
| `codex/.codex/skills/<name>` | `agent-suite/platforms/codex/skills/<name>` |

Stowing yields a chain — `~/.claude/skills` → `claude/.claude/skills` →
`agent-suite/skills` — which every harness resolves transparently.

The `codex` package links **per skill** rather than linking the `skills` directory
whole, because `~/.codex/skills` is Codex's own directory: it holds the bundled
`.system` skills. Stow descends into it and adds the suite's skills alongside them.
That also means adding a skill to Codex needs `stow --restow codex`, unlike the
claude and opencode packages where the whole directory is one link.

**Changes to an agent, skill, or command belong in the submodule**, not here. Follow
`agent-suite/README.md` for its sync and validation rules; its own CI enforces them.
Editing a suite file is live immediately, same as any other symlinked file. Persisting
it takes two steps:

```sh
cd agent-suite && git commit ... && git push   # the real change
cd .. && git add agent-suite && git commit     # bump the pointer dotfiles records
```

The pointer bump can be batched — dotfiles simply lags the suite until you make one.
On a fresh machine, clone with `--recurse-submodules` (or run `git submodule update
--init`) before stowing, or the symlinks dangle.

## The `claude/` package is the live Claude Code config

`claude/.claude/` is symlinked to `~/.claude/`, so editing files here edits the active
Claude Code configuration. Beyond the submodule symlinks above, it holds `settings.json`
and the other harness-local files.

## Managing it

`make help` lists the targets. The two worth knowing:

```sh
make check    # every suite link resolves, then the suite's own validator
make relink   # repair the links and restow codex
```

`make check` covers something neither repo's own tooling can. The suite's
`validate-config.py` runs inside the submodule and cannot see this repo, so a skill
shared to codex upstream can pass every check there while never reaching Codex,
because the `codex` package has no matching link. `scripts/links.py` owns that
manifest — the seven whole-directory links plus one per codex skill — and `--relink`
repairs anything missing, wrong, or stale.

`make status` shows which packages are stowed; `make install` checks out the
submodule and stows everything; `make update` pulls the latest suite revision.

## Conventions

- Commits use Conventional Commits, scoped by package name (e.g. `docs(readme): ...`,
  `feat(claude): ...`, `chore(tmux): ...`). Repo-root files like this one and `README.md`
  use a descriptive scope such as `readme`, not a package scope.
- A submodule pointer bump uses the scope `agent-suite`.
- Never read or commit secret-bearing files (`.env`, keys, credentials).
- Keep `README.md` in sync when adding, removing, or renaming a package.
