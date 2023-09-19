-- Comment/uncomment selected lines in Visual mode
vim.api.nvim_set_keymap('x', 'vc', ':Commentary<CR>', { noremap = true, silent = true })

-- Comment/uncomment current line in Normal mode
vim.api.nvim_set_keymap('n', 'vc', ':Commentary<CR>', { noremap = true, silent = true })


