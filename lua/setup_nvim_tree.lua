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


