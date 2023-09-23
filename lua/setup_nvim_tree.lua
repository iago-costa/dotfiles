require'nvim-tree'.setup {

}

-- Config nvim-tree.lua keybindings
vim.api.nvim_set_keymap('n', '<Leader>nt', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>no', ':NvimTreeOpen<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nf', ':NvimTreeFocus<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nff', ':NvimTreeFindFile<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nc', ':NvimTreeCollapse<CR>', { noremap = true, silent = true })

-- Automatically open NvimTree when Neovim starts
-- vim.cmd [[
-- autocmd VimEnter * NvimTreeOpen
-- ]]


-- init doc key
-- {'n'} <Leader>nt = toggle nvim tree
-- {'n'} <Leader>no = open nvim tree
-- {'n'} <Leader>nf = focus nvim tree
-- {'n'} <Leader>nff = find file in nvim tree
-- {'n'} <Leader>nc = collapse nvim tree
-- end doc key
