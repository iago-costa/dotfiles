-- Map <C-<Leader>> to comment out lines in insert mode
vim.keymap.set('i', '<C-\\>', '<Esc>:Commentary<CR>', { noremap = true, silent = true })

-- Map <Leader>h to comment out lines in normal mode
vim.keymap.set({ 'n', 'x' }, '<Leader>h', ':Commentary<CR>', { noremap = true, silent = true })


-- init doc key
-- {'n', 'x'} <leader>h = Comment out line
-- {'i'} <C-\\> = Comment out line
-- end doc key
