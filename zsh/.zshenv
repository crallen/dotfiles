# Sourced by every zsh process: keep it to cheap env and PATH. No secrets here.

# Environment
export LANG=en_US.UTF-8
export EDITOR=nvim
export VISUAL=nvim
export BUN_INSTALL=~/.bun

# PATH: prepend user dirs that exist, deduplicated
typeset -U path
path=(~/.local/bin(N/) ~/.bun/bin(N/) ~/.opencode/bin(N/) $path)

# Per-machine overrides
[[ -r ~/.zshenv.local ]] && source ~/.zshenv.local
