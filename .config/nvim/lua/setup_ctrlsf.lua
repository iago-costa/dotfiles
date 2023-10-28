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
map('n', '<C-s>w', ':CtrlSF<CR>', options)


-- init doc key
-- {'n'} <C-s>t = :CtrlSFToggle<CR>
-- {'n'} <C-s>w = :CtrlSF<CR>
-- end doc key
