# ===========================================================================
# Options
# ===========================================================================
setopt auto_cd auto_pushd pushd_ignore_dups interactive_comments extended_glob no_beep

# ===========================================================================
# History
# ===========================================================================
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history share_history hist_ignore_all_dups hist_ignore_space \
  hist_reduce_blanks hist_find_no_dups hist_save_no_dups

# ===========================================================================
# Completion
# ===========================================================================
autoload -Uz compinit
_zcompdump=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}
# Full compinit regenerates the dump; -C reuses it while it is under 24h old.
if [[ -n ${_zcompdump}(#qN.mh-24) ]]; then
  compinit -C -d $_zcompdump
else
  compinit -d $_zcompdump
  touch $_zcompdump  # compinit leaves an unchanged dump untouched; restart the 24h clock
fi
unset _zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
[[ -z $LS_COLORS ]] && (( $+commands[dircolors] )) && eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ===========================================================================
# Keys
# ===========================================================================
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Fixed codes cover normal and application keypad modes, so bindings work even
# when $TERM has no terminfo entry (Ghostty over SSH); terminfo adds any extras.
typeset -A _keys=(
  '^[[A' up-line-or-beginning-search    '^[OA' up-line-or-beginning-search
  '^[[B' down-line-or-beginning-search  '^[OB' down-line-or-beginning-search
  '^[[H' beginning-of-line  '^[OH' beginning-of-line  '^[[1~' beginning-of-line
  '^[[F' end-of-line        '^[OF' end-of-line        '^[[4~' end-of-line
  '^[[3~' delete-char
  '^[[1;5D' backward-word   '^[[1;5C' forward-word
)
for _seq _widget in ${(kv)_keys}; do
  bindkey -- $_seq $_widget
done

zmodload zsh/terminfo
_keys=(
  kcuu1 up-line-or-beginning-search
  kcud1 down-line-or-beginning-search
  khome beginning-of-line
  kend  end-of-line
  kdch1 delete-char
  kLFT5 backward-word
  kRIT5 forward-word
)
for _cap _widget in ${(kv)_keys}; do
  [[ -n ${terminfo[$_cap]} ]] && bindkey -- ${terminfo[$_cap]} $_widget
done
unset _keys _seq _cap _widget

# ===========================================================================
# Aliases
# ===========================================================================
alias ls='ls --color=auto'
alias ll='ls -lhFA'
alias grep='grep --color=auto'

# ===========================================================================
# Plugins
# ===========================================================================
# Sources the first path that exists; silent when none do.
_source_first() {
  local f
  for f in "$@"; do
    [[ -r $f ]] && { source $f; return 0; }
  done
  return 1
}

_source_first \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

if (( $+commands[fzf] )); then
  autoload -Uz is-at-least
  _fzf_version=${$(fzf --version 2>/dev/null)%% *}
  if [[ -n $_fzf_version ]] && is-at-least 0.48 $_fzf_version; then
    source <(fzf --zsh)
  else
    _source_first \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/doc/fzf/examples/key-bindings.zsh
  fi
  unset _fzf_version
fi

# ===========================================================================
# Secrets
# ===========================================================================
# Loaded only when ~/.zsh_secrets is a regular file owned by this user with
# no group or other permission bits. Never changes permissions itself.
_load_secrets() {
  local f=~/.zsh_secrets
  local -a mode
  [[ -e $f || -L $f ]] || return 0
  zmodload -F zsh/stat b:zstat
  if [[ -f $f && ! -L $f && -O $f ]] && zstat -A mode +mode $f &&
     (( (mode[1] & 8#077) == 0 )); then
    source $f
  else
    print -u2 'zsh: ~/.zsh_secrets not loaded: permissions must be 600 (chmod 600 ~/.zsh_secrets)'
  fi
}
_load_secrets

# ===========================================================================
# Prompt
# ===========================================================================
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else
  PROMPT='%~ %# '
fi

# ===========================================================================
# Local overrides
# ===========================================================================
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# ===========================================================================
# Syntax highlighting (must follow every widget definition)
# ===========================================================================
_source_first \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
