
# Dotfiles
tmux + zsh + nvim



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
