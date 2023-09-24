vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true


-- Option 3: treesitter as a main provider instead
-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
-- use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}
require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        return {'treesitter', 'indent'}
    end
})

-- Keymaps to toggle ufo
vim.api.nvim_set_keymap('n', '<leader>zr', ':lua require("ufo").openAllFolds()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>zm', ':lua require("ufo").closeAllFolds()<CR>', {noremap = true, silent = true})


-- init doc key
-- {'n'} <leader>zr = openAllFolds
-- {'n'} <leader>zm = closeAllFolds
-- {'n'} zr = openCurrentFold
-- {'n'} zm = closeCurrentFold
-- end doc key
