-- toogle term
vim.keymap.set('n', '<leader>lt', [[<Cmd>ToggleTerm<CR>]])

-- split term horizontally
vim.keymap.set('n', '<leader>lth', [[<Cmd>ToggleTerm size=20 direction=horizontal<CR>]])

-- split term vertically
vim.keymap.set('n', '<leader>ltv', [[<Cmd>ToggleTerm size=70 direction=vertical<CR>]])

function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')


-- init doc key
-- {'n'} <leader>lt = toggle term
-- {'n'} <leader>lth = split term horizontally
-- {'n'} <leader>ltv = split term vertically
-- keymaps only in buffer terminal mode below
-- {'t'} <esc> = exit terminal mode
-- {'t'} jk = exit terminal mode
-- {'t'} <C-h> = move to left window
-- {'t'} <C-j> = move to bottom window
-- {'t'} <C-k> = move to top window
-- {'t'} <C-l> = move to right window
-- {'t'} <C-w> = exit terminal mode
-- end doc key
