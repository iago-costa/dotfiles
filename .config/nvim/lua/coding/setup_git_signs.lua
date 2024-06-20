require('gitsigns').setup {
  signs                        = {
    add          = { text = 'a│' },
    change       = { text = 'c│' },
    delete       = { text = 'd_' },
    topdelete    = { text = 'd‾' },
    changedelete = { text = 'd~' },
    untracked    = { text = 'u┆' },
  },
  signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl                        = true,  -- Toggle with `:Gitsigns toggle_numhl`
  linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff                    = true,  -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir                 = {
    follow_files = true
  },
  attach_to_untracked          = true,
  current_line_blame           = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts      = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
  sign_priority                = 6,
  update_debounce              = 100,
  status_formatter             = nil,   -- Use default
  max_file_length              = 40000, -- Disable if file is longer than this (in lines)
  preview_config               = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
}

-- Keymaps
vim.api.nvim_set_keymap('n', '<leader>gs', ':Gitsigns toggle_signs<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gn', ':Gitsigns next_hunk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gp', ':Gitsigns prev_hunk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gr', ':Gitsigns reset_hunk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gR', ':Gitsigns reset_buffer<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gp', ':Gitsigns preview_hunk<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gb', ':Gitsigns blame_line<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gs', ':Gitsigns stage_hunk<CR>', { noremap = true, silent = true })

-- Toggle current line blame
vim.api.nvim_set_keymap('n', '<leader>Gb', ':Gitsigns toggle_current_line_blame<CR>', { noremap = true, silent = true })
-- Toggle word diff
vim.api.nvim_set_keymap('n', '<leader>Gw', ':Gitsigns toggle_word_diff<CR>', { noremap = true, silent = true })



-- init doc key
-- {'n'} <leader>gs = :Gitsigns toggle_signs<CR>
-- {'n'} <leader>gn = :Gitsigns next_hunk<CR>
-- {'n'} <leader>gp = :Gitsigns prev_hunk<CR>
-- {'n'} <leader>gr = :Gitsigns reset_hunk<CR>
-- {'n'} <leader>gR = :Gitsigns reset_buffer<CR>
-- {'n'} <leader>gp = :Gitsigns preview_hunk<CR>
-- {'n'} <leader>gb = :Gitsigns blame_line<CR>
-- {'n'} <leader>gs = :Gitsigns stage_hunk<CR>
-- {'n'} <leader>Gb = :Gitsigns toggle_current_line_blame<CR>
-- {'n'} <leader>Gw = :Gitsigns toggle_word_diff<CR>
-- end doc key
