-- Ensure packer is installed
if vim.fn.empty(vim.fn.glob(vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim')) then
    vim.fn.system({ 'git', 'clone', 'https://github.com/wbthomason/packer.nvim', '--depth', '1',
        vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim' })
end

-- Load setup_packer.lua
require('setup_packer')

-- Load plugins configuration from plugins.lua
require('plugins')

-- Load mason to install LSP servers
require("mason").setup()

if not vim.g.vscode then
    -- Load lsp configuration from setup_lsp.lua
    require('setup_lsp')

    -- Load lsp configuration for dart from lsp_dart.lua
    require('lsp_dart')

    -- Load lsp configuration for flutter from lsp_flutter.lua
    require('lsp_flutter')

    -- Load lsp configuration for rust from lsp_rust.lua
    require('lsp_rust')

    -- Load lsp configuration for python from lsp_python.lua
    require('lsp_python')

    -- Load lsp configuration for lua from lsp_css.lua
    require('lsp_css')

    -- Load lsp configuration for lua from lsp_javascript.lua
    require('lsp_javascript')

    -- Load lsp configuration for lua from lsp_lua.lua
    require('lsp_lua')

    -- Load treesitter configuration from treesitter.lua
    require('tree_sitter')

    -- Load harpoon configuration for lua from harpoon.lua
    require('setup_harpoon')

    -- Load undotree configuration for lua from undotree.lua
    require('undo_tree')

    -- Enable setup_nvim_tree.lua
    require('setup_nvim_tree')

    -- Load toggleterm configuration from toggle_term.lua
    require('toggle_term')

    -- Load telescope configuration from telescope.lua
    require('setup_telescope')

    -- Load vim-matchup configuration from vim_matchup.lua
    require('vim_matchup')

    -- Load refactoring configuration for lua from refactoring.lua
    require('setup_refactoring')

    -- Load trouble configuration for lua from trouble.lua
    require('setup_trouble')

    -- Load setup_auto_save.lua
    require('setup_auto_save')

    -- Load setup_lazy_git.lua
    require('setup_lazy_git')

    -- Load setup_doc_keymap.lua
    require('setup_doc_keymap')

    -- Load setup_git_signs.lua
    require('setup_git_signs')

    -- Load setup_ctrlsf.lua
    require('setup_ctrlsf')

    -- Load setup_command_completion.lua
    require('setup_command_completion')

    -- Load setup_nvim_ufo.lua
    require('setup_nvim_ufo')

    -- Load setup_multi_tabs.lua
    require('setup_multi_tabs')
end

-- Load commentary configuration from commentary.lua
require('commentary')

-- Load lsp configuration auto-completion from lsp_cmp.lua
require('lsp_cmp')

-- Load custom commands and options from global_cmds.lua, global_opts.lua and global_keys.lu
require('global_cmds')
require('global_opts')
require('global_keys')

-- Load colors.lua
require('colors')
