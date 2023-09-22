-- Map Ctrl + _ to comment out lines in insert mode
vim.api.nvim_set_keymap('i', '<C-\\>', '<Esc>:Commentary<CR>', { noremap = true, silent = true })

-- Map Ctrl + _ to comment out lines in normal mode
vim.api.nvim_set_keymap('n', '<Leader>h', ':Commentary<CR>', { noremap = true, silent = true })

-- Map Ctrl + _ to comment out lines in visual mode
vim.api.nvim_set_keymap('x', '<Leader>h', ':Commentary<CR>', { noremap = true, silent = true })




-- init doc key
-- {'n', 'x'} <leader>h : Comment out line
-- {'i'} <C-\\> : Comment out line
-- end doc key
