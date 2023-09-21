# Pre-config to nvim.
(And optional but super recommended) -> Pre-config for tmux and zsh

### Major references
1. (https://quickref.me/vim)
2. [](https://github.com/ThePrimeagen/init.lua)

## Commands nvim
    v = Visual Mode
    V = Visual line mode
    <Alt-otherkey> = Out insert mode
    y = Copy selected text (visual mode) 
    P = paste selected text (visual mode) 
    > = tab text (visual mode)
    < = same of the '>'
    R = set replace mode
    u = undo change 
    <Ctrl-R> = redo change
    w = Move cursor by word
    b = Move cursor back word
    aw = Select word
    iw = Select inner word
    i( = Select inner text in parentheses
    a( = Select inner text in parentheses
    gu = Lowercase selected text
    gU = Uppercase selected text
    gUw = Capitalize the word UNDER the cursor
    :<line-number> = goto the line-number
    g"" = Convert text to snake case
    h,j,k,l = left,bottom,top,right
    Del = delete an char
    dd = cut lines
    dW = cut word
    D = cut from the cursor position to the end of the line
    d0 = cut from the cursor position to the beginning of the line
    :<lineN>,<lineN>d = cut range of lines
    G = Move to the end of the document
    gg = Move to beginning of the document
    <Ctrl-u> = page up
    <Ctrl-d> = page down
    <Ctrl-o> = jump previous cursor position
    <Ctrl-i> = jump next cursor position
     :%s/old-word/new-word/g = 
    <Ctrl-W> + <Ctrl-W> = change the screen in focus
    gg = jump cursor to the top of the file (visual mode) 
    ggvG = Select all lines in file
    * = search all ocurrencies

## Move cursor: Within a Line:
    Start of Line: 0 = Moves the cursor to the beginning of the current line.
    First Non-Blank Character of Line: ^ = Moves the cursor to the first non-blank character of the current line.
    End of Line: $ = Moves the cursor to the end of the current line.
    Next Word: w = Moves the cursor forward by one word.
    Previous Word: b = Moves the cursor backward by one word.

## Move cursor: Through the File:
    First Line: gg = Moves the cursor to the first line of the file.
    Last Line: G = Moves the cursor to the last line of the file.
    Line Number: :<line_number> = Replace <line_number> with the line number you want to jump to. For example, :15 will jump to line 15.
    Search for a Pattern: / = Opens the search prompt, allowing you to search for a specific pattern in the file. After typing the pattern, press Enter to jump to the next occurrence.
    Next Occurrence: n = After performing a search, this will move the cursor to the next occurrence of the pattern.
    Previous Occurrence: N = After performing a search, this will move the cursor to the previous occurrence of the pattern.
    Top of the Screen: H = Moves the cursor to the top of the screen.
    Middle of the Screen: M = Moves the cursor to the middle of the screen.
    Bottom of the Screen: L = Moves the cursor to the bottom of the screen.

## Native Commands nvim-tree
    a = Create files and folders
    r = Rename files and folders
    Y = Copy relative Path
    W = Collapse


## To install Neovim on Old date distros from a tar.gz file, you can follow these steps:

1. **Prerequisites**:

Make sure you have `curl` and `tar` installed. If not, you can install them using the following command:
 ```bash
 sudo apt-get update
 sudo apt-get install curl tar
 ```

2. **Download Neovim**:

You can download the latest release of Neovim from the official GitHub repository using `curl`. Replace `VERSION` with the desired version (e.g., `0.5.1`).

```bash
curl -LO https://github.com/neovim/neovim/releases/download/vVERSION/nvim-linux64.tar.gz
```

For the latest version, you can check the releases page on the Neovim GitHub repository: https://github.com/neovim/neovim/releases

3. **Extract the Tarball**:

Once the tar.gz file is downloaded, you can extract it using the following command:

```bash
tar -xzvf nvim-linux64.tar.gz
```

This command will extract the contents of the tarball into a directory named `nvim-linux64`.

4. **Move Neovim to /usr/local**:

It's a good practice to move Neovim to the `/usr/local` directory to make it available system-wide. Use the following command to move the extracted files:

```bash
sudo mv nvim-linux64 /usr/local/
```

5. **Create Symbolic Links**:

Create symbolic links to the `nvim` executable in a directory that's included in your system's `PATH`. This makes it easier to run Neovim from the command line. Typically, `/usr/local/bin` is included in the `PATH`.

```bash
sudo ln -s /usr/local/nvim-linux64/bin/nvim /usr/local/bin/nvim
```

6. **Verify Installation**:

You can verify that Neovim is installed correctly by running the following command:

```bash
nvim --version
```

This command should display the version information for Neovim.

Now, Neovim should be installed on your Ubuntu system from the tar.gz file. You can start using Neovim by simply typing `nvim` in the terminal.

## Config for tmux

1. **Install tmux**:
Use package manager from your distro.

2. To persist Tmux sessions across reboots and ensure they are automatically restored when you restart your computer, you can use a tool called `tmux-resurrect`. `tmux-resurrect` is a Tmux plugin that allows you to save and restore Tmux sessions and their contents. Here's how to set it up:

**Step 1: Install Tmux Plugin Manager (TPM) (if not already installed)**

If you haven't already installed TPM, you can do so by running the following command:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**Step 2: Configure Tmux to Use `tmux-resurrect`**

Edit your `~/.tmux.conf` file (or create it if it doesn't exist) and add the following lines to enable `tmux-resurrect`:

```bash
# Initialize TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'

# Restore and save sessions with tmux-resurrect
set -g @plugin 'tmux-plugins/tmux-resurrect'
```

Reload Tmux to apply these changes by running:

```bash
tmux source-file ~/.tmux.conf
```

**Step 3: Save and Restore Sessions**

Now that you have `tmux-resurrect` configured, you can save your Tmux session before shutting down your computer and automatically restore it when you start it up again:

- To save your current Tmux session, press `Ctrl-b` (the Tmux prefix key, followed by `Ctrl-s` (for "save").

- To restore your saved session after restarting your computer, press `Ctrl-b` followed by `Ctrl-r` (for "restore").

**Step 4: Install 'tmux-continuum' (optional, but recommended)**

`tmux-continuum` is another Tmux plugin that works well in conjunction with `tmux-resurrect` to automate the process. It periodically saves your sessions and provides additional options for customization.

To install `tmux-continuum`, add the following line to your `~/.tmux.conf` file:

```bash
set -g @plugin 'tmux-plugins/tmux-continuum'
```

Then, run `tmux source-file ~/.tmux.conf` to apply the changes.

With `tmux-continuum` installed, it will automatically save your Tmux sessions and restore them when you start Tmux.

By following these steps, your Tmux sessions will be automatically persisted and restored across computer reboots, making it convenient to pick up where you left off.
        
## Tmux file .tmux.conf
```bash
# Initialize TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'

# Restore and save sessions with tmux-resurrect
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Continuum keeps tmux environment up to date
set -g @plugin 'tmux-plugins/tmux-continuum'

# Automatically save the Tmux session every few minutes (e.g., every 1 minutes).
set -g @resurrect-save-interval 60

# Restore saved sessions on Tmux startup.
run-shell '$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh'

# Enable mouse support (for scrolling with the mouse wheel).
set -g mouse on

# Use Vi-like key bindings for copy mode (optional).
setw -g mode-keys vi    
```

## Zsh file .zshrc
1. Link To install/configure: [Instal/Configure zsh and plugins](https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df) 

2. Standard configuration
```bash
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=$HOME/bin:/usr/local/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

SAVEHIST=99999

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
    npm # you added this
    thefuck
    docker
    docker-compose
    timer
    fasd
    direnv
    dirhistory
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

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

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -TFl --group-directories-first --icons --git -L 2 --no-user $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:pacman:*' fzf-preview 'pacman -Si $word'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git show --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'


[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
# export SDKMANAGER=/home/gup/Android/Sdk/cmdline-tools/latest/bin
export ANDROID_SDK_ROOT=/home/gup/Android/Sdk/
export PATH=$SDKMANAGER:$PATH
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
export PATH=/opt/flutter/bin:$PATH
export RUST_BACKTRACE=full

[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
```
