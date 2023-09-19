-- Keymaps
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<leader>lg", "<cmd>LazyGit<CR>", opts)
map("n", "<leader>lc", "<cmd>LazyGitConfig<CR>", opts)
map("n", "<leader>lf", "<cmd>LazyGitFilter<CR>", opts)
map("n", "<leader>lff", "<cmd>LazyGitFilterCurrentFile<CR>", opts)
