-- Set to search hidden files
vim.api.nvim_set_var('telescope', {
    defaults = {
        file_ignore_patterns = { 'node_modules', 'dist', 'build', 'target', 'vendor', 'yarn.lock', 'package-lock.json' },
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',
            '--glob',
            '!.git/**',
            '--glob',
            '!node_modules/**',
            '--glob',
            '!dist/**',
            '--glob',
            '!build/**',
            '--glob',
            '!target/**',
            '--glob',
            '!vendor/**',
            '--glob',
            '!yarn.lock',
            '--glob',
            '!package-lock.json',
        },
    },
})


-- Config telescope.nvim keybindings
vim.api.nvim_set_keymap('n', '<Leader>tf', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>tg', ':Telescope live_grep<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>tb', ':Telescope buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>th', ':Telescope help_tags<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>tgf', ':Telescope git_files<CR>', { noremap = true, silent = true })

vim.keymap.set("n", "<leader>tC", function()
  require("telescope").extensions.diff.diff_files({ hidden = true })
end, { desc = "Compare 2 files" })
vim.keymap.set("n", "<leader>tc", function()
  require("telescope").extensions.diff.diff_current({ hidden = true })
end, { desc = "Compare file with current" })

-- init doc key
-- {'n'} <Leader>tf = find files
-- {'n'} <Leader>tg = live grep
-- {'n'} <Leader>tb = buffers
-- {'n'} <Leader>th = help tags
-- {'n'} <Leader>tgf = git files
-- {'n'} <Leader>tC = compare 2 files
-- {'n'} <Leader>tc = compare file with current
-- end doc key
