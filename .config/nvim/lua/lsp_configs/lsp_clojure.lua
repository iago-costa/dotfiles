-- Config the keybindings to be used in conjure

-- ConjureEval

vim.api.nvim_set_keymap('n', '<leader>ee', '<cmd>ConjureEval<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>ev', '<cmd>ConjureEvalVisual<cr>', { noremap = true, silent = true })

-- ConjureLog
-- vim.api.nvim_set_keymap('n', '<leader>l', '<cmd>ConjureLog<cr>', { noremap = true, silent = true })
--
-- ConjureEvalRootForm
-- ConjureEvalCurrentForm
vim.api.nvim_set_keymap('n', '<leader>er', '<cmd>ConjureEvalRootForm<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>ConjureEvalCurrentForm<cr>', { noremap = true, silent = true })

-- ConjureLogToggle
vim.api.nvim_set_keymap('n', '<leader>el', '<cmd>ConjureLogToggle<cr>', { noremap = true, silent = true })

-- ConjureEvalFile
vim.api.nvim_set_keymap('n', '<leader>ef', '<cmd>ConjureEvalFile<cr>', { noremap = true, silent = true })

-- ConjureEvalBuf
vim.api.nvim_set_keymap('n', '<leader>eb', '<cmd>ConjureEvalBuf<cr>', { noremap = true, silent = true })

-- init doc key
-- {'n'} <leader>ee = ConjureEval
-- {'v'} <leader>ev = ConjureEvalVisual
-- {'n'} <leader>el = ConjureLog
-- {'n'} <leader>er = ConjureEvalRootForm
-- {'n'} <leader>e = ConjureEvalCurrentForm
-- {'n'} <leader>el = ConjureLogToggle
-- {'n'} <leader>ef = ConjureEvalFile
-- {'n'} <leader>eb = ConjureEvalBuf
-- end doc key
