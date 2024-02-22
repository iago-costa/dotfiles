# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
# export PATH=$JAVA_HOME/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
# export PATH=$JAVA_HOME/bin:$PATH
# export SDKMANAGER=/home/gup/Android/Sdk/cmdline-tools/latest/bin
# export ANDROID_SDK_ROOT=/home/gup/Android/Sdk/
# export PATH=$SDKMANAGER:$PATH
# export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
# export PATH=/opt/flutter/bin:$PATH

# export PATH=/opt/asdf-vm/bin:$PATH
# export ASDF_DIR=$HOME/.asdf
# export ASDF_SHELL=/opt/asdf-vm/asdf.sh

export RUST_BACKTRACE=none


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

SAVEHIST=99999

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# plugins=(git)
plugins=(
	git 
	zsh-autosuggestions 
	zsh-syntax-highlighting 
	fast-syntax-highlighting 
	zsh-autocomplete
  bundler
  dotenv
  rake
  rbenv
	ruby
  npm
	thefuck
	docker
	docker-compose
	timer
	fasd
	direnv
  dirhistory
	fzf-tab
  zellij
  gh
  alias-finder
  adb
  ansible
  aws
  azure
  git-flow
  kubectl
  minikube
  terraform
  yarn
  vault
  nmap
  helm
  gradle
  git-lfs
  deno
  node
  emacs
  flutter
  git-flow
  gitfast
  lein
  microk8s
  singlechar
  sudo
  git-prompt
)

source $ZSH/oh-my-zsh.sh

# Include directories in fasd's database
export _FASD_BLACKLIST_CMDLINE_DIRS=false
export _FASD_BLACKLIST_DIRS=""

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection
alias op="fzf --print0 | xargs -0 -o xdg-open $1"
alias opd="find / -type d | fzf --print0 | xargs -0 -o xdg-open $1"

alias thefix='fuck'
alias xmonadinit='pkill -f "xmonad" | true | xmonad --recompile &> /dev/null | true && xmonad --replace &'
alias xmobarinit='pkill -f "xmobar" | true && xmobar &'
alias xmoinit='xmonadinit; xmobarinit;'

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -TFl --group-directories-first --icons --git -L 2 --no-user $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:pacman:*' fzf-preview 'pacman -Si $word'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git show --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# fcd - fuzzy cd
fcd() {
    local selected_dir
    selected_dir=$(find "$1" -type d | fzf +m)  # Recursively list directories and use fzf for selection
    if [ -n "$selected_dir" ]; then
        cd "$selected_dir" || return  # Change to the selected directory
    fi
}

# tm.zsh
# Simplifies creating new tmux sessions, attaching to existing sessions,
# switching between sessions, and listing active sessions.
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
  tmux has -t="$1" 2> /dev/null && tmux $change -t "$1" || (TMUX= tmux new -d -s "$1" && tmux $change -t "$1")
}

function __tmux-sessions() {
  local expl
  local -a sessions
  sessions=( ${${(f)"$(command tmux list-sessions 2> /dev/null)"}/:[ $'\t']##/:} )
  _describe -t sessions 'sessions' sessions "$@"
}
compdef __tmux-sessions tm
# end tm.zsh
alias t="tmux switchc -t"

unset ZSH_AUTOSUGGEST_USE_ASYNC
