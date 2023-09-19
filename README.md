-- https://quickref.me/vim

## Commands nvim
    v = Visual Mode
    V = Visual line mode
    <Alt-otherkey> = Out insert mode
    y = Copy selected text (visual mode) 
    P = paste selected text (visual mode) 
    > = tab (visual mode)
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

Within a Line:

Start of Line: 0 = Moves the cursor to the beginning of the current line.
First Non-Blank Character of Line: ^ = Moves the cursor to the first non-blank character of the current line.
End of Line: $ = Moves the cursor to the end of the current line.
Next Word: w = Moves the cursor forward by one word.
Previous Word: b = Moves the cursor backward by one word.

Through the File:

First Line: gg = Moves the cursor to the first line of the file.
Last Line: G = Moves the cursor to the last line of the file.
Line Number: :<line_number> = Replace <line_number> with the line number you want to jump to. For example, :15 will jump to line 15.
Search for a Pattern: / = Opens the search prompt, allowing you to search for a specific pattern in the file. After typing the pattern, press Enter to jump to the next occurrence.
Next Occurrence: n = After performing a search, this will move the cursor to the next occurrence of the pattern.
Previous Occurrence: N = After performing a search, this will move the cursor to the previous occurrence of the pattern.
Top of the Screen: H = Moves the cursor to the top of the screen.
Middle of the Screen: M = Moves the cursor to the middle of the screen.
Bottom of the Screen: L = Moves the cursor to the bottom of the screen.

## Commands nvim-tree
    a = Create files and folders
    r = Rename files and folders
    Y = Copy relative Path
    W = Collapse


To install Neovim on Ubuntu from a tar.gz file, you can follow these steps:

1. **Prerequisites**:

   - Make sure you have `curl` and `tar` installed. If not, you can install them using the following command:
     ```
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
