#!/usr/bin/env python3
"""Check and repair the symlinks wiring the agent-suite submodule into the Stow packages.

The packages hold no suite content of their own — every agent, skill, command, and
index document is a symlink into `agent-suite/`. Two shapes exist:

  whole-directory  claude and opencode link a directory (or file) in one hop, so a
                   skill added upstream is live with no action here
  per-skill        codex links each skill individually, because ~/.codex/skills is
                   Codex's own directory and holds its bundled .system set

The per-skill shape is the one that drifts: a skill shared to codex upstream needs a
matching link here, and the suite's own validator cannot see this repo.

    scripts/links.py            report every expected link; exit 1 on any problem
    scripts/links.py --relink   create what is missing, fix what points wrong
    scripts/links.py -q         only problems and the summary
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(
    subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
)

SUITE = "agent-suite"

# Links whose target never changes. Relative, so they resolve on any machine.
FIXED: list[tuple[str, str]] = [
    ("claude/.claude/agents",              f"../../{SUITE}/agents"),
    ("claude/.claude/skills",              f"../../{SUITE}/skills"),
    ("claude/.claude/commands",            f"../../{SUITE}/platforms/claude/commands"),
    ("claude/.claude/CLAUDE.md",           f"../../{SUITE}/platforms/claude/CLAUDE.md"),
    ("opencode/.config/opencode/agent",    f"../../../{SUITE}/platforms/opencode/agent"),
    ("opencode/.config/opencode/commands", f"../../../{SUITE}/platforms/opencode/commands"),
    ("opencode/.config/opencode/skills",   f"../../../{SUITE}/platforms/opencode/skills"),
    ("opencode/.config/opencode/AGENTS.md", f"../../../{SUITE}/platforms/opencode/AGENTS.md"),
    ("codex/.codex/AGENTS.md",             f"../../{SUITE}/platforms/codex/AGENTS.md"),
]

CODEX_PKG = "codex/.codex/skills"
CODEX_SRC = f"{SUITE}/platforms/codex/skills"

problems: list[str] = []


def fail(msg: str) -> None:
    problems.append(msg)


def codex_expected() -> list[tuple[str, str]]:
    """One link per skill the suite shares with codex."""
    src = ROOT / CODEX_SRC
    if not src.is_dir():
        fail(f"{CODEX_SRC} is missing — is the submodule checked out?")
        return []
    return [
        (f"{CODEX_PKG}/{d.name}", f"../../../{CODEX_SRC}/{d.name}")
        for d in sorted(src.iterdir())
        if d.is_dir() or d.is_symlink()
    ]


def inspect(rel: str, want: str) -> str:
    """Classify one expected link: ok, or the reason it is not."""
    p = ROOT / rel
    if not p.is_symlink():
        return "missing" if not p.exists() else "not a symlink"
    got = os.readlink(p)
    if got != want:
        return f"points at {got}"
    if not p.resolve().exists():
        return f"dangling -> {want}"
    return "ok"


def repair(rel: str, want: str, state: str) -> str:
    p = ROOT / rel
    if state == "not a symlink":
        return "refused: a real file or directory is in the way"
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.is_symlink():
        p.unlink()
    p.symlink_to(want)
    return "relinked" if state != "missing" else "created"


def stray_codex_links(expected: set[str]) -> list[Path]:
    """Links under the codex package with no counterpart upstream."""
    pkg = ROOT / CODEX_PKG
    if not pkg.is_dir():
        return []
    return [d for d in sorted(pkg.iterdir())
            if d.is_symlink() and f"{CODEX_PKG}/{d.name}" not in expected]


def check_live(quiet: bool, codex_probe: str | None) -> None:
    """Confirm the stowed links under ~ resolve all the way to real files.

    A package the user has not stowed is reported, not failed — which packages are
    applied on a given machine is their choice.

    The codex probe is a single skill rather than the skills directory: that
    directory belongs to Codex and holds its bundled .system set, so stow links
    each skill inside it instead of the directory itself.
    """
    home = Path.home()
    probes = [
        ("claude",   home / ".claude/skills"),
        ("opencode", home / ".config/opencode/skills"),
    ]
    if codex_probe:
        probes.append(("codex", home / ".codex/skills" / codex_probe))
    for pkg, path in probes:
        if not path.exists() and not path.is_symlink():
            if not quiet:
                print(f"  --    {pkg:<10} not stowed")
            continue
        target = path.resolve()
        if not target.exists():
            fail(f"~/{path.relative_to(home)} is stowed but dangles")
        elif ROOT not in target.parents and target != ROOT:
            fail(f"~/{path.relative_to(home)} resolves outside the repo -> {target}")
        elif not quiet:
            print(f"  ok    {pkg:<10} ~/{path.relative_to(home)} -> {target.relative_to(ROOT)}")


def main() -> int:
    relink = "--relink" in sys.argv
    quiet = "-q" in sys.argv or "--quiet" in sys.argv

    expected = FIXED + codex_expected()
    print(f"{'relinking' if relink else 'checking'} {len(expected)} suite links "
          f"({len(FIXED)} whole-directory, {len(expected) - len(FIXED)} codex skills)\n")

    acted = 0
    for rel, want in expected:
        state = inspect(rel, want)
        if state == "ok":
            if not quiet:
                print(f"  ok    {rel}")
            continue
        if relink:
            outcome = repair(rel, want, state)
            if outcome.startswith("refused"):
                fail(f"{rel}: {outcome}")
            else:
                print(f"  {outcome:<5} {rel}")
                acted += 1
        else:
            fail(f"{rel}: {state}")

    for stray in stray_codex_links({rel for rel, _ in expected}):
        rel = stray.relative_to(ROOT)
        if relink:
            stray.unlink()
            print(f"  removed {rel} (no longer shared upstream)")
            acted += 1
        else:
            fail(f"{rel}: linked here but not shared by the suite")

    print()
    codex_names = [Path(rel).name for rel, _ in expected if rel.startswith(CODEX_PKG)]
    check_live(quiet, codex_names[0] if codex_names else None)

    if problems:
        print("\nproblems:")
        for p in problems:
            print(f"  - {p}")
        hint = "" if relink else "\nRun scripts/links.py --relink to repair what it can."
        print(f"\n{len(problems)} problem(s).{hint}")
        return 1
    print(f"\nall {len(expected)} links good{f'; {acted} changed' if acted else ''}.")
    if acted:
        print("Run `make relink` or `stow --restow codex` so the new links reach ~.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
