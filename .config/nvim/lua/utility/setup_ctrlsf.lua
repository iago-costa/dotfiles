-- keymaps CtrlSF
-- nmap     <C-F>f <Plug>CtrlSFPrompt
-- vmap     <C-F>f <Plug>CtrlSFVwordPath
-- vmap     <C-F>F <Plug>CtrlSFVwordExec
-- nmap     <C-F>n <Plug>CtrlSFCwordPath
-- nmap     <C-F>p <Plug>CtrlSFPwordPath
-- nnoremap <C-F>o :CtrlSFOpen<CR>
-- nnoremap <C-F>t :CtrlSFToggle<CR>
-- inoremap <C-F>t <Esc>:CtrlSFToggle<CR>


local map = vim.api.nvim_set_keymap
local options = { noremap = true, silent = true }


map('n', '<C-s>t', ':CtrlSFToggle<CR>', options)
map('v', '<C-s>v', '<Plug>CtrlSFVwordPath<CR>', options)
map('v', '<C-s>V', '<Plug>CtrlSFVwordExec<CR>', options)
map('n', '<C-s>n', '<Plug>CtrlSFCwordPath<CR>', options)
map('n', '<C-s>p', '<Plug>CtrlSFPwordPath<CR>', options)

-- init doc key
-- {'n'} <C-s>t = :CtrlSFToggle<CR>
-- Enter, o, double-click = Open corresponding file of current line in the window which CtrlSF is launched
-- {'b'} <C-O> = Like Enter but open file in a horizontal split window.
-- {'b'} t = Like Enter but open file in a new tab.
-- {'b'} p = Like Enter but open file in a preview window.
-- {'b'} P = Like Enter but open file in a preview window and switch focus to it.
-- {'b'} O = Like Enter but always leave CtrlSF window opening.
-- {'b'} T = Like t but focus CtrlSF window instead of new opened tab.
-- {'b'} M = Switch result window between normal view and compact view.
-- {'b'} q = Quit CtrlSF window.
-- {'b'} <C-J> = Move cursor to next match.
-- {'b'} <C-N> = Move cursor to next file's first match.
-- {'b'} <C-K> = Move cursor to previous match.
-- {'b'} <C-P> = Move cursor to previous file's first match.
-- {'b'} <C-C> = Stop a background searching process.
-- {'b'} <C-T> = Use fzf for faster navigation. In the fzf window, use <Enter> to focus specific match and <C-O> to open matched file.
-- :CtrlSF -S foo = Case-sensitive search.
-- :CtrlSF -W foo = Match whole word.
-- :CtrlSF -R foo = Use regex to search.
-- :CtrlSF -I foo = Ignore case.
-- :CtrlSF -hidden = Search hidden files and directories.
-- :CtrlSF -L = Literal string search.
-- :CtrlSF -ignoredir = Ignore directories.
-- :CtrlSF -T = Search by file types.
-- :CtrlSF -G = Search by file match.
-- :CtrlSF -smart-case foo = Smart case.
-- {'v'} <C-s>v = <Plug>CtrlSFVwordPath<CR> : Input Search for the word under cursor.
-- {'v'} <C-s>V = <Plug>CtrlSFVwordExec<CR> : Search for the word under cursor and execute the matched result.
-- {'n'} <C-s>n = <Plug>CtrlSFCwordPath<CR> : Input Search for the word under cursor.
-- {'n'} <C-s>p = <Plug>CtrlSFPwordPath<CR> : Input Search with the last search pattern.
--- end doc key
