-- Comment/uncomment selected lines in Visual mode use Ctrl . 
-- vim.api.nvim_set_keymap('v', '<C-.>', ':Commentary<CR>', { noremap = true, silent = true })

-- Comment/uncomment current line in Normal mode
vim.api.nvim_set_keymap('n', 'vc', ':Commentary<CR>', { noremap = true, silent = true })




-- init doc key
-- {'n'} vc : comment/uncomment current line
-- end doc key
