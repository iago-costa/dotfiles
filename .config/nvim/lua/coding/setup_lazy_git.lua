-- Keymaps
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<leader>gl", "<cmd>LazyGit<CR>", opts)
map("n", "<leader>lc", "<cmd>LazyGitConfig<CR>", opts)
map("n", "<leader>lf", "<cmd>LazyGitFilter<CR>", opts)
map("n", "<leader>lff", "<cmd>LazyGitFilterCurrentFile<CR>", opts)


-- init doc key
-- {'n'} <leader>gl = open lazygit
-- {'n'} <leader>lc = open lazygit config
-- {'n'} <leader>lf = open lazygit filter
-- {'n'} <leader>lff = open lazygit filter current file
-- end doc key
