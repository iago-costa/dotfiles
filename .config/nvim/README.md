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

