# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ══════════════════════════════════════════════════════════
# PATH (deduplicated)
# ══════════════════════════════════════════════════════════
typeset -U path PATH                    # Enforce unique entries — prevents PATH bloat across sessions
export PATH="$HOME/bin:$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# ══════════════════════════════════════════════════════════
# Oh-My-Zsh Configuration
# ══════════════════════════════════════════════════════════
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugin settings (must be set before sourcing oh-my-zsh)
ZSH_DOTENV_PROMPT=false                       # Auto-source .env silently (p10k compat)
typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
typeset -g ZSH_AUTOSUGGEST_STRATEGY=(history completion)
DISABLE_UNTRACKED_FILES_DIRTY="true"          # Faster git status in large repos
ENABLE_CORRECTION="false"                     # Disabled — frequent false positives cause hangs
export RUST_BACKTRACE=none

# ══════════════════════════════════════════════════════════
# History (crash-safe)
# ══════════════════════════════════════════════════════════
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # Share history across sessions
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
setopt HIST_VERIFY            # Don't execute immediately on history expansion
setopt INC_APPEND_HISTORY     # Write immediately, don't wait for shell exit
setopt HIST_FCNTL_LOCK        # Use kernel-level locking (prevents corruption)
setopt HIST_EXPIRE_DUPS_FIRST # When history is full, expire duplicates before unique entries

# ══════════════════════════════════════════════════════════
# Safety Options (prevent crashes & data loss)
# ══════════════════════════════════════════════════════════
setopt NO_CLOBBER             # Prevent accidental file overwrite with >
setopt NO_BG_NICE             # Don't lower priority of background jobs
setopt NO_HUP                 # Don't kill background jobs on shell exit
setopt NO_BEEP                # No bell on errors
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive mode
setopt LONG_LIST_JOBS         # Show PID in job list for easier management
setopt LOCAL_TRAPS            # Traps set in functions are restored on return

# Harden against crashes — increase stack size to prevent segfaults
# on deep recursion (zsh-autocomplete, large completions)
ulimit -s 32768 2>/dev/null   # 32MB stack (default 8MB is too low)

# Crash recovery — log fatal signals for debugging
TRAPTERM()  { return 128; }
TRAPSEGV()  { echo "[zsh] SEGV caught — shell recovering" >&2; return 139; }
TRAPABRT()  { echo "[zsh] ABRT caught — shell recovering" >&2; return 134; }

# ══════════════════════════════════════════════════════════
# Completion System (optimized, cached)
# ══════════════════════════════════════════════════════════
# Only rebuild completion dump once per day (major speedup)
autoload -Uz compinit
() {
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump-${ZSH_VERSION}"
  if [[ -n $zcompdump(#qN.mh+24) ]]; then
    compinit -d "$zcompdump"
  else
    compinit -C -d "$zcompdump"  # -C = skip security check (faster)
  fi
}

# ══════════════════════════════════════════════════════════
# Plugins
# ══════════════════════════════════════════════════════════
# IMPORTANT: zsh-autocomplete removed — it conflicts with fzf-tab
# and causes crashes (both override ZLE widgets for completion).
# fzf-tab is more stable and integrates better with fzf ecosystem.
#
# Removed for performance:
#   - fasd: redundant with zoxide (which is faster and already loaded)
#   - emacs: overrides emacs with emacsclient (not needed, we use nvim)
#   - gitfast: redundant — git plugin already provides completions
#   - alias-finder: hooks preexec on every command, adds latency
plugins=(
  # Core experience
  git
  git-lfs
  git-flow
  gh
  sudo                  # Press ESC twice to prepend sudo
  dirhistory            # Alt+Left/Right to navigate dir history
  direnv                # Auto-load .envrc files
  dotenv                # Auto-source .env files
  timer                 # Show command execution time

  # Completions & UI
  zsh-autosuggestions
  fast-syntax-highlighting
  fzf-tab

  # Languages & tools (only installed ones)
  npm
  node
  deno
  yarn
  docker
  docker-compose
  ansible
  kubectl
  helm
  terraform
  nmap
)

source $ZSH/oh-my-zsh.sh

# ══════════════════════════════════════════════════════════
# Modern Tool Initialization (cached for speed)
# ══════════════════════════════════════════════════════════
# Cache init scripts — only regenerate when the binary is updated.
# Saves ~80-120ms per startup compared to `eval "$(... init zsh)"`.
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init-cache"
[[ -d "$_cache_dir" ]] || mkdir -p "$_cache_dir"

_cached_init() {
  local name="$1" cmd="$2"
  local cache_file="$_cache_dir/${name}.zsh"
  local bin_path="${commands[$name]}"
  # Regenerate if cache is missing or binary is newer than cache
  if [[ -z "$bin_path" ]]; then
    return 1  # Binary not installed
  elif [[ ! -f "$cache_file" || "$bin_path" -nt "$cache_file" ]]; then
    eval "$cmd" > "$cache_file" 2>/dev/null || return 1
  fi
  source "$cache_file"
}

_cached_init zoxide  "zoxide init zsh"
_cached_init pay-respects "pay-respects init zsh"

unset _cache_dir
unfunction _cached_init 2>/dev/null

# ══════════════════════════════════════════════════════════
# Aliases — Modern CLI Replacements (guarded)
# ══════════════════════════════════════════════════════════
# Each alias is guarded — if the tool isn't installed, the
# original system command is preserved instead of breaking.

# File listing (eza replaces ls/exa)
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -alh --icons --group-directories-first --git'
  alias lt='eza -T --icons --group-directories-first -L 3'
fi

# File viewing
(( $+commands[bat] ))   && alias cat='bat --style=auto' && alias catn='bat --style=plain'

# Search
(( $+commands[rg] ))    && alias grep='rg'

# Disk usage
(( $+commands[dust] ))  && alias du='dust'
(( $+commands[duf] ))   && alias df='duf'

# Process viewing
(( $+commands[procs] )) && alias ps='procs'

# Quick edit
(( $+commands[nvim] ))  && alias vi='nvim' && alias vim='nvim'

# ══════════════════════════════════════════════════════════
# Aliases — Fuzzy Finders & Openers
# ══════════════════════════════════════════════════════════
alias op="fzf --print0 | xargs -0 -o xdg-open"
# Use fd (fast) scoped to $HOME instead of find / (dangerous — scans entire filesystem)
alias opd="fd --type d . ~ | fzf --print0 | xargs -0 -o xdg-open"

# ══════════════════════════════════════════════════════════
# Aliases — VMs
# ══════════════════════════════════════════════════════════
alias win10='~/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/scripts/win10-vm.sh'
alias macos='~/GITS/INC_FILES/STUDY_PROGRAMMING/dotfiles/scripts/macos-vm.sh'

# ══════════════════════════════════════════════════════════
# FZF-Tab Previews (guarded)
# ══════════════════════════════════════════════════════════
if (( $+commands[eza] )); then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -TFl --group-directories-first --icons --git -L 2 --no-user $realpath'
fi

if (( $+commands[bat] )); then
  zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
  zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
fi

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Git previews
if (( $+commands[delta] )); then
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
fi
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git show --color=always $word'
if (( $+commands[bat] )); then
  zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'
fi

# NixOS package preview
zstyle ':fzf-tab:complete:nix:*' fzf-preview 'nix eval --raw "nixpkgs#$word.meta.description" 2>/dev/null || echo "No description"'

# ══════════════════════════════════════════════════════════
# Editor
# ══════════════════════════════════════════════════════════
export EDITOR='nvim'
export VISUAL='nvim'

# ══════════════════════════════════════════════════════════
# Custom Functions
# ══════════════════════════════════════════════════════════

# fcd - fuzzy cd (recursive directory picker)
fcd() {
    local selected_dir
    selected_dir=$(fd --type d "${1:-.}" | fzf +m --preview 'eza -T --icons -L 2 {}')
    [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

# tm - tmux session manager
function tm() {
  [[ -z "$1" ]] && {
    echo "Usage: tm <session>"
    SESSIONS=$(tmux ls -F "* #{session_name}" 2>/dev/null)
    if [[ -n $SESSIONS ]]; then
      echo "Active tmux sessions:"
      echo "$SESSIONS"
    else
      echo "No tmux server running"
    fi
    return
  }
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  tmux has -t="$1" 2>/dev/null && tmux $change -t "$1" || (TMUX= tmux new -d -s "$1" && tmux $change -t "$1")
}
function __tmux-sessions() {
  local expl
  local -a sessions
  sessions=( ${${(f)"$(command tmux list-sessions 2>/dev/null)"}/:[ $'\t']##/:} )
  _describe -t sessions 'sessions' sessions "$@"
}
compdef __tmux-sessions tm
alias t="tmux switchc -t"

# ══════════════════════════════════════════════════════════
# Powerlevel10k
# ══════════════════════════════════════════════════════════
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

unset ZSH_AUTOSUGGEST_USE_ASYNC
