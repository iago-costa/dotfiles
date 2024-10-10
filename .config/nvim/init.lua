-- Ensure packer is installed
if vim.fn.empty(vim.fn.glob(vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim')) then
  vim.fn.system({ 'git', 'clone', 'https://github.com/wbthomason/packer.nvim', '--depth', '1',
    vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim' })
end

-- files to search for lua modules
vim.o.runtimepath = vim.o.runtimepath .. ',' .. vim.fn.expand('~/.config/nvim/lua') .. ',' ..
    vim.fn.expand('~/.local/share/nvim/site/pack/packer/start/*')

-- Load setup_packer.lua
require('setup_packer')

-- Load plugins configuration from plugins.lua
require('plugins')

-- Load mason to install LSP servers
require("mason").setup()

if not vim.g.vscode then
  -- Load lsp configuration from setup_lsp.lua
  require('lsp_configs/setup_lsp')

  -- Load lsp configuration for dart from lsp_dart.lua
  require('lsp_configs/lsp_dart')

  -- Load lsp configuration for flutter from lsp_flutter.lua
  require('lsp_configs/lsp_flutter')

  -- Load lsp configuration for rust from lsp_rust.lua
  require('lsp_configs/lsp_rust')

  -- Load lsp configuration for python from lsp_python.lua
  require('lsp_configs/lsp_python')

  -- Load lsp configuration for lua from lsp_css.lua
  require('lsp_configs/lsp_css')

  -- Load lsp configuration for lua from lsp_javascript.lua
  require('lsp_configs/lsp_javascript')

  -- Load lsp configuration for lua from lsp_lua.lua
  require('lsp_configs/lsp_lua')

  -- Load lsp_go.lua
  require('lsp_configs/lsp_go')

  -- Load lsp_cpp.lua
  require('lsp_configs/lsp_cpp')

  -- Load lsp_clojure.lua
  require('lsp_configs/lsp_clojure')

  -- Load null_ls.lua
  -- require('lsp_configs/null_ls')

  -- Load lsp configuration for java from lsp_java.lua
  require('lsp_configs/lsp_java')
  -- require('ftplugin/lsp_java')

  -- Load treesitter configuration from treesitter.lua
  require('utility/tree_sitter')

  -- Load harpoon configuration for lua from harpoon.lua
  require('utility/setup_harpoon')

  -- Load undotree configuration for lua from undotree.lua
  require('utility/undo_tree')

  -- Load telescope configuration from telescope.lua
  require('utility/setup_telescope')

  -- Load trouble configuration for lua from trouble.lua
  require('utility/setup_trouble')

  -- Load setup_auto_save.lua
  require('utility/setup_auto_save')

  -- Load setup_ctrlsf.lua
  require('utility/setup_ctrlsf')

  -- Load setup_nvim_ufo.lua
  require('utility/setup_nvim_ufo')

  -- Load setup_buffer_manager.lua
  require('utility/setup_buffer_manager')

  -- Load setup_auto_session.lua
  require('utility/setup_auto_session')

  -- Load setup_wilder.lua
  require('utility/setup_wilder')

  -- Load setup_spectre.lua
  require('utility/setup_spectre')

  -- Load setup_doc_keymap.lua
  require('utility/setup_doc_keymap')

  -- Load refactoring configuration for lua from refactoring.lua
  require('coding/setup_refactoring')

  -- Load setup_lazy_git.lua
  require('coding/setup_lazy_git')

  -- Load setup_git_signs.lua
  require('coding/setup_git_signs')

  require('coding/dap_mapping')

  -- Load vim-matchup configuration from vim_matchup.lua
  require('styles/vim_matchup')

  -- Load setup_lualine.lua
  require('styles/setup_lualine')

  -- Load setup_statusline.lua
  -- require('styles/setup_statusline') -- short implementation of statusline
end

-- Load commentary configuration from commentary.lua
require('coding/commentary')

-- Load lsp configuration auto-completion from lsp_cmp.lua
require('lsp_configs/lsp_cmp')

-- Load colors.lua
require('styles/colors')

-- Load custom commands and options from global_cmds.lua, global_opts.lua and global_keys.lu
require('global_cmds')
require('global_opts')
require('global_keys')

vim.lsp.set_log_level("WARN")
