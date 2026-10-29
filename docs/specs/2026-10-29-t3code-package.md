# t3code package

## Goal

Move the T3 Code server's systemd user unit and start script out of
`homelab-services` into a `t3code` stow package, so any machine (first `megamaki`)
gets the same server from `make install`. The start script stops hardcoding a node
path: it inherits the shell's PATH from `~/.zshenv`, whose baseline now puts the
newest installed nvm node on PATH. Machines without nvm can name another node in
`~/.zshenv.local`.

## Context

- Today's setup lives in `~/code/homelab-services/t3code/`:
  - `t3-serve.service`: `Wants`/`After=network-online.target`, `Restart=on-failure`,
    `RestartSec=5`, `WantedBy=default.target`.
  - `t3-serve.sh`: bash; prepends `~/.nvm/versions/node/v24.15.0/bin` to PATH, then
    `exec npx --yes t3@latest serve --host 127.0.0.1 --port 3773 "$@"`.
  - `install.sh`: symlinks the unit into `~/.config/systemd/user/` and enables it.
  - `README.md`: also documents this host's Traefik route, dnsmasq/split-DNS, T3
    Connect, and pairing.
- Linger is on for this machine.
- `claude` and `codex` live in `~/.local/bin`, already on the zsh baseline's PATH.
  Only `node`/`npx` come from nvm.
- Both this machine and `megamaki` use nvm. nvm here holds v22.22.2, v24.15.0, v24.17.0; `default` is `lts/*`, resolving to
  v24.17.0. The glob `~/.nvm/versions/node/v*(/nOn[1])` picks the same directory.
- zsh reads `~/.zshenv` for every invocation, scripts included, and never reads
  `.zshrc` for a script, so a zsh start script gets the baseline PATH and no secrets.
- `~/.local/bin` and `~/.config/systemd/user` are real directories here, so stow
  links the two files individually.

## Approach

A `t3code` stow package holding the unit and a zsh start script. `make install`
stows it, then enables the unit. PATH policy stays in one place: `.zshenv` (with the
nvm node glob in the baseline) plus the machine's `.zshenv.local`. Loading `nvm.sh`
stays in `~/.zshrc.local`: it is slow and only needed for interactive `nvm use`.

Rejected: keeping it in `homelab-services` (a homelab repo on a work box); a script
that searches for node itself (a second PATH policy); requiring distro node.

## Components

### `t3code/.local/bin/t3-serve`

Executable, `#!/usr/bin/env zsh`. A comment explains that PATH comes from
`~/.zshenv` and `~/.zshenv.local`. Body:
`exec npx --yes t3@latest serve --host 127.0.0.1 --port 3773 "$@"`.

### `t3code/.config/systemd/user/t3-serve.service`

The current unit with its comments, `ExecStart=%h/.local/bin/t3-serve`.

### `Makefile`

- Add `t3code` to `ALL`.
- New `t3-enable` target: exits 0 unless `t3code` is in `PACKAGES`; runs
  `systemctl --user daemon-reload` and `systemctl --user enable --now t3-serve.service`;
  warns with the `sudo loginctl enable-linger "$USER"` command when
  `loginctl show-user "$USER" -p Linger --value` is not `yes`. Never restarts a
  running server.
- `install` calls it after the stow loop; a stow conflict exits before reaching it.

### `README.md` and `CLAUDE.md`

README: `t3code/` in the layout tree and symlink list, requirements (node and the
agent CLIs on the `.zshenv` PATH), and a `### t3code` section covering the files,
the PATH model with the per-machine node line, linger, operations
(`systemctl --user restart t3-serve`, `journalctl --user -u t3-serve -f`, `t3@latest`
re-resolving on each start), and remote access (laptop via SSH; phone via
`npx t3@latest pair --tailscale` or T3 Connect `connect login --headless` +
`connect link`). CLAUDE.md: package table rows.

### `zsh/.zshenv` (baseline)

Add `~/.nvm/versions/node/v*/bin(/nOn[1]N)` to the existing `path=(...)` line, after
`~/.opencode/bin`. Gives every shell, non-interactive ones and the service included,
the newest installed nvm node; matches nothing on a machine without nvm. Update the
README `zsh` section: the node bin dir comes from the baseline; only `nvm.sh` loading
belongs in `~/.zshrc.local`.

### `homelab-services`

Delete `t3code/t3-serve.service`, `t3code/t3-serve.sh`, `t3code/install.sh`. Cut
`t3code/README.md` to this host's access and auth content (Traefik route, why the
split, authentication, T3 Connect) with a pointer to dotfiles for the unit and
script. Lands as a Forgejo PR.

## Error Handling

- No node on PATH: `npx` not found, the unit fails and retries every 5s. README
  says to install node via nvm or set it in `~/.zshenv.local`.
- Linger off: `t3-enable` warns and continues.
- Existing unit symlink into `homelab-services`: stow reports `CONFLICT`; task 5
  removes the link first.
- `t3code` not in `PACKAGES`: `t3-enable` is a no-op.

## Testing

1. `zsh -n t3code/.local/bin/t3-serve`; the file is executable.
2. `systemd-analyze --user verify t3code/.config/systemd/user/t3-serve.service` passes.
3. `env -i HOME=$HOME zsh -c 'command -v node npx claude codex'` finds all four here,
   with `node` under `~/.nvm/versions/node/v24.17.0/bin`; with a throwaway HOME and
   no `~/.nvm`, `zsh -c 'print -l $path'` gains no nvm entry and prints no error.
4. `stow -n -v -t $(mktemp -d) t3code` links only the unit and the script.
5. `make t3-enable PACKAGES=claude` does nothing.
6. After migration: `systemctl --user show t3-serve -p FragmentPath` resolves to the
   dotfiles copy; `systemctl --user is-enabled t3-serve` prints `enabled`.
7. After the user restarts the service: `systemctl --user is-active t3-serve` is
   `active`, `curl -s 127.0.0.1:3773/api/health` responds, and the T3 app reconnects.

## Risks & Open Questions

- **Risk**: restarting `t3-serve` restarts the server this agent session runs on.
  Task 5 stops after swapping files; the user restarts when convenient. The running
  server keeps working on the old script until then.
- **Risk**: the newest-version glob can diverge from nvm's `default` if a non-newest
  default is pinned. They match today; a machine that needs a different node can
  prepend it in `~/.zshenv.local`, which `.zshenv` sources after setting `path`.
- **Risk**: `t3@latest` resolves from npm on every start; unchanged from today.

## Task Checklist

- [x] 1. Create `t3code/.local/bin/t3-serve`: executable zsh script that execs
  `npx --yes t3@latest serve --host 127.0.0.1 --port 3773 "$@"`.
- [x] 2. Create `t3code/.config/systemd/user/t3-serve.service`: the current unit with
  `ExecStart=%h/.local/bin/t3-serve`.
- [x] 3. `Makefile`: add `t3code` to `ALL`; add gated `t3-enable` (daemon-reload,
  `enable --now`, linger warning); call it from `install` after the stow loop.
- [x] 4. Update `README.md` (layout, symlink list, requirements, `t3code` section, and
  the `zsh` section's nvm note) and the `CLAUDE.md` package table. (blocked by 1, 2, 3, 7)
- [x] 5. Migrate this machine: remove
  the `~/.config/systemd/user/t3-serve.service` symlink into `homelab-services`; add
  `t3code` to `packages.local`; run `make install`; run Testing 3 and 6; hand the
  restart to the user. (blocked by 1, 2, 3, 7)
- [x] 6. `homelab-services`: delete the three files, cut `t3code/README.md` to this
  host's access and auth content with a pointer to dotfiles, open a Forgejo PR.
  (blocked by 5)
- [x] 7. `zsh/.zshenv`: add `~/.nvm/versions/node/v*/bin(/nOn[1]N)` to the `path=(...)`
  line after `~/.opencode/bin`.
