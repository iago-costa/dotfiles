# Pre-config to nvim.
(And optional but super recommended) -> Pre-config for tmux and zsh

### Major references
1. [quickref-vim](https://quickref.me/vim)
2. [ThePrimeagen-Config-nvim](https://github.com/ThePrimeagen/init.lua)

### Plus ./lua/setup_doc_keymap.lua
An plugin to document and fast see all your custom keymaps
An example in final of file: ./lua/global_keys.lua
Preset keymap <Leader>m == \m

Enjoy!

## Major used commands nvim
    {'n'} ggVG = select all
    {'n'} <C-r> = redo
    {'n'} <S-p> = paste
    {'n'} F = find in line backward
    {'n'} f = find in line forward
    {'n'} <C-d> = move cursor down page
    {'n'} <C-u> = move cursor up page
    {'n'} K = move cursor to below line
    {'n'} J = move cursor to above line
    {'v'} K = move selected line / block of text up
    {'v'} J = move selected line / block of text down
    <Ctrl-o> = jump previous cursor position
    <Ctrl-i> = jump next cursor position
    Vim Operators ------------------
    {'n'} d = delete
    {'n'} c = change
    {'n'} y = yank
    {'n'} > = indent right
    {'n'} < = indent left
    {'n'} ! = filter through external program
    {'n'} gq = format lines
    {'n'} gu = make lowercase
    {'n'} gU = make uppercase
    {'n'} = = filter through equalprg
    {'n'} g? = rot13 encoding
    {'n'} g~ = swap case
    Vim Text Objects ----------------
    {'n'} vaw = select a word
    {'n'} viw = select inner word
    {'n'} caw = change a word
    {'n'} ciw = change inner word
    {'n'} yaw = yank a word
    {'n'} yiw = yank inner word
    {'n'} dap = delete a paragraph
    {'n'} dip = delete inner paragraph
    Vim Macros ---------------------
    {'n'} qi = Record macro i
    {'n'} q = Stop recording macro
    {'n'} @i = Run macro i
    {'n'} 7@i = Run macro i 7 times
    {'n'} @@ = Repeat last macro
    Vim Repeat ---------------------
    {'n'} . = Repeat last command
    {'n'} ; = Repeat latest f, t, F or T
    {'n'} , = Repeat latest f, t, F or T reversed
    {'n'} & = Repeat last :s
    {'n'} @: = Repeat a command-line command
    Combinations -------------------
    {'n'} ggdG = Delete a complete document
    {'n'} ggVG = Indent a complete document
    {'n'} ggyG	= Copy a whole document


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

## Tmux file .tmux.conf
- see in the root repository folder

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
        
### Most used keybindings for tmux
1. Save session
    <Ctrl-b><Ctrl-s>
    Restore session

2. Create vertical window
    <Ctrl-b> @

3. Create horizontal window
    <Ctrl-b> "

4. Change the pane active
    <Ctrl-b> [Arrow keys]

You use space bar for the beginning of the selection and enter for the end.

5. copy:
    Ctrl-b [ -- initiate the copy mode
    Space -- activate select
    Enter -- Copy

6. paste:
    Ctrl-b ]

7. Update the modification in .tmux.conf
    tmux source-file ~/.tmux.conf

8. Create new session named
    tmux new -s <session_name>

9. Attach an old session named
    tmux a -t <session_name>

10. Rename current session
    Ctrl-b $

11. Toggle full screen actual pane
    Ctrl-b z

12. Change position actual pane
    Ctrl-b } or Ctrl { 

13. Circulate positions to actual pane
    Ctrl-b Ctrl-o

## Zsh file .zshrc
1. Link To install/configure: [Instal/Configure zsh and plugins](https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df) 

## asdf to manage multiples versions of programming languages
```bash
asdf plugin add <plugin_name>
asdf install <plugin_name> <plugin_version>
# Need to make works asdf
source /opt/asdf-vm/asdf.sh 
asdf local <plugin_name> <plugin_version>
```

## top terminal tools
1. navi -- terminal snippets
    - navi fn welcome
    - navi
2. zoxide -- smart cd
3. fcd
    - combination fzf + cd
4. fasd -- fast cd 
