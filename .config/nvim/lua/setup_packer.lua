-- Config packer keybindings
vim.api.nvim_set_keymap('n', '<Leader>pi', ':PackerInstall<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>pu', ':PackerUpdate<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>pc', ':PackerClean<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>ps', ':PackerSync<CR>', { noremap = true, silent = true })


