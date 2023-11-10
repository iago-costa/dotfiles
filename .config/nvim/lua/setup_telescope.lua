-- Set to search hidden files
vim.api.nvim_set_var('telescope', {
    defaults = {
        -- file_ignore_patterns = { 'node_modules', 'dist', 'build', 'target', 'vendor', 'yarn.lock', 'package-lock.json',
        -- '__pycache__' },
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',
            -- '--glob',
            -- '!.git/**',
            -- '--glob',
            -- '!node_modules/**',
            -- '--glob',
            -- '!dist/**',
            -- '--glob',
            -- '!build/**',
            -- '--glob',
            -- '!target/**',
            -- '--glob',
            -- '!vendor/**',
            -- '--glob',
            -- '!yarn.lock',
            -- '--glob',
            -- '!package-lock.json',
        },
    },
})

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Config telescope.nvim keybindings

map('n', 'tgh', '<Cmd>lua require("telescope.builtin").git_stash()<CR>', opts)
map('n', 'tgc', '<Cmd>lua require("telescope.builtin").git_commits()<CR>', opts)
map('n', 'tgs', '<Cmd>lua require("telescope.builtin").git_status()<CR>', opts)
map('n', 'tgb', '<Cmd>lua require("telescope.builtin").git_branches()<CR>', opts)
map('n', 'tgf', '<Cmd>lua require("telescope.builtin").git_files()<CR>', opts)

map('n', 'tf', '<Cmd>lua require("telescope.builtin").find_files()<CR>', opts)
map('n', 'tq', '<Cmd>lua require("telescope.builtin").quickfix()<CR>', opts)
map('n', 'tl', '<Cmd>lua require("telescope.builtin").loclist()<CR>', opts)
map('n', 'tp', '<Cmd>lua require("telescope.builtin").live_grep()<CR>', opts)

map('n', 'tr', '<Cmd>lua require("telescope.builtin").lsp_references()<CR>', opts)
map('n', 'tdi', '<Cmd>lua require("telescope.builtin").diagnostics()<CR>', opts)
map('n', 'ti', '<Cmd>lua require("telescope.builtin").lsp_implementations()<CR>', opts)
map('n', 'td', '<Cmd>lua require("telescope.builtin").lsp_definitions()<CR>', opts)

map('n', 'tb', ':Telescope buffers<CR>', opts)
map('n', 'th', ':Telescope help_tags<CR>', opts)

map('n', 'tt', '<Cmd>lua require("telescope.builtin").treesitter()<CR>', opts)

vim.keymap.set("n", "tC", function()
    require("telescope").extensions.diff.diff_files({ hidden = true })
end, { desc = "Compare 2 files" })
vim.keymap.set("n", "tc", function()
    require("telescope").extensions.diff.diff_current({ hidden = true })
end, { desc = "Compare file with current" })

-- local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")

local telescope = require("telescope")

telescope.setup {
    defaults = {
        mappings = {
            i = { ["<c-t>"] = trouble.open_with_trouble },
            n = { ["<c-t>"] = trouble.open_with_trouble },
        },
    },
}

map('n', 't,', '<Cmd>lua require("telescope.builtin").registers()<CR>', opts)
map('n', 't.', '<Cmd>lua require("telescope.builtin").jumplist()<CR>', opts)
map('n', 't/', '<Cmd>lua require("telescope.builtin").keymaps()<CR>', opts)
map('n', 'tm', '<Cmd>lua require("telescope.builtin").man_pages()<CR>', opts)
map('n', 'ts', '<Cmd>lua require("telescope.builtin").spell_suggest()<CR>', opts)
map('n', 'to', '<Cmd>lua require("telescope.builtin").oldfiles()<CR>', opts)
map('n', 't;', '<Cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>', opts)

-- builtin.grep_string
map('n', 'tes', '<Cmd>lua require("telescope.builtin").grep_string()<CR>', opts)

-- init doc key
-- {'n'} tgh = builtin.git_stash
-- {'n'} tgc = builtin.git_commits
-- {'n'} tgs = builtin.git_status
-- {'n'} tgb = builtin.git_branches
-- {'n'} tgf = builtin.git_files
-- {'n'} tf = find_files
-- {'n'} tq = builtin.quickfix
-- {'n'} tl = builtin.loclist
-- {'n'} tp = builtin.live_grep
-- {'n'} tr = builtin.lsp_references
-- {'n'} tdi = builtin.diagnostics
-- {'n'} ti = builtin.lsp_implementations
-- {'n'} td = builtin.lsp_definitions
-- {'n'} tt = builtin.treesitter
-- {'n'} tb = buffers
-- {'n'} th = help_tags
-- {'n'} tC = Compare 2 files
-- {'n'} tc = Compare file with current
-- {'n'} t, = builtin.registers
-- {'n'} t. = builtin.jumplist
-- {'n'} t/ = builtin.keymaps
-- {'n'} tm = builtin.man_pages
-- {'n'} ts = builtin.spell_suggest
-- {'n'} to = builtin.oldfiles
-- {'n'} t; = builtin.current_buffer_fuzzy_find
-- -- end doc key
