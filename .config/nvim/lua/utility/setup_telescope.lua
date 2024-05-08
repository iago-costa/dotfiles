-- local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")

local telescope = require("telescope")

telescope.setup {
  defaults = {
    file_ignore_patterns = {
      'node_modules', 'dist', 'build', 'target/', 'vendor', 'yarn.lock', 'package-lock.json', '__pycache__', '.git', 'bin/' },
    -- vimgrep_arguments = {
    --   'rg', '--ignore', '--hidden' },
    mappings = {
      i = { ["<c-t>"] = trouble.open_with_trouble },
      n = { ["<c-t>"] = trouble.open_with_trouble },
    },
  },
  extensions = {
    advanced_git_search = {
      -- fugitive or diffview
      diff_plugin = "fugitive",
      -- customize git in previewer
      -- e.g. flags such as { "--no-pager" }, or { "-c", "delta.side-by-side=false" }
      git_flags = { "-c", "delta.side-by-side=true" },
      -- customize git diff in previewer
      -- e.g. flags such as { "--raw" }
      git_diff_flags = {},
      -- Show builtin git pickers when executing "show_custom_functions" or :AdvancedGitSearch
      show_builtin_git_pickers = true,
      entry_default_author_or_date = "date", -- one of "author" or "date"

      -- Telescope layout setup
      telescope_theme = {
        -- e.g. realistic example
        show_custom_functions = {
          layout_config = { width = 0.4, height = 0.4 },
        },

      }
    },
    file_browser = {
      theme = "ivy",
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
      mappings = {
        ["i"] = {
          -- your custom insert mode mappings
        },
        ["n"] = {
          -- your custom normal mode mappings
        },
      },
    },
  },
  pickers = {
    find_files = {
      hidden = true,
      -- find_command = {
      --   'fd',
      --   '--type',
      --   'f',
      --   '--no-ignore-vcs',
      --   '--color=never',
      --   '--hidden',
      --   '--follow',
      -- },
      find_command = {
        'rg',
        '--files',
        '--hidden',
        '--no-ignore-vcs',
        '--glob',
        '!.git',
        '--glob',
        '!node_modules',
        '--glob',
        '!dist',
        '--glob',
        '!build',
        '--glob',
        '!target',
        '--glob',
        '!vendor',
        '--glob',
        '!*.lock',
        '--glob',
        '!package-lock.json',
        '--glob',
        '!__pycache__',
        '--glob',
        '!bin',
        '--glob',
        '!undodir',
      },
    },
  },

}

telescope.load_extension("file_browser")

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Config telescope.nvim keybindings
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


map('n', 't,', '<Cmd>lua require("telescope.builtin").registers()<CR>', opts)
map('n', 't.', '<Cmd>lua require("telescope.builtin").jumplist()<CR>', opts)
map('n', 't/', '<Cmd>lua require("telescope.builtin").keymaps()<CR>', opts)
map('n', 'tm', '<Cmd>lua require("telescope.builtin").man_pages()<CR>', opts)
map('n', 'te', '<Cmd>lua require("telescope.builtin").spell_suggest()<CR>', opts)
map('n', 'to', '<Cmd>lua require("telescope.builtin").oldfiles()<CR>', opts)
map('n', 't;', '<Cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>', opts)

-- builtin.grep_string
map('n', 'tps', '<Cmd>lua require("telescope.builtin").grep_string()<CR>', opts)

map('n', 'tgh', '<Cmd>lua require("telescope.builtin").git_stash()<CR>', opts)
map('n', 'tgc', '<Cmd>lua require("telescope.builtin").git_commits()<CR>', opts)
map('n', 'tgs', '<Cmd>lua require("telescope.builtin").git_status()<CR>', opts)
map('n', 'tgb', '<Cmd>lua require("telescope.builtin").git_branches()<CR>', opts)
map('n', 'tgf', '<Cmd>lua require("telescope.builtin").git_files()<CR>', opts)

-- Telescope extensions advanced_git_search
map('n', 'tsd', '<Cmd>Telescope advanced_git_search diff_commit_file<CR>', opts)
map('n', 'tsl', '<Cmd>Telescope advanced_git_search diff_commit_line<CR>', opts)
map('n', 'tsb', '<Cmd>Telescope advanced_git_search diff_branch_file<CR>', opts)
map('n', 'tsc', '<Cmd>Telescope advanced_git_search search_log_content_file<CR>', opts)

-- open file_browser with the path of the current buffer
map("n", "<Leader>t", "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>", opts)

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
-- {'n'} tps = builtin.grep_string
-- {'n'} tsd = advanced_git_search diff_commit_file
-- {'n'} tsl = advanced_git_search diff_commit_line
-- {'n'} tsb = advanced_git_search diff_branch_file
-- {'n'} tsc = advanced_git_search search_log_content_file
-- {'n'} fb = file_browser with the path of the current buffer
-- -- end doc key
