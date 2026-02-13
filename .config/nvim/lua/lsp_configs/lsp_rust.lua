-- Configure Rust Analyzer
-- Use vim.lsp.config (Nvim 0.11+)
-- local nvim_lsp = require('lspconfig') -- Deprecated

local on_attach = function(client)
  require 'completion'.on_attach(client)
end

-- define config manually for vim.lsp.config
vim.lsp.config['rust_analyzer'] = {
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      imports = {
        granularity = {
          group = "module",
        },
        prefix = "self",
      },
      cargo = {
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true
      },
    }
  }
}
vim.lsp.enable('rust_analyzer')


-- local rust_tools = require('rust-tools')
-- rust_tools.setup({
--   server = {
--     on_attach = function(client, bufnr)
--       -- Hover actions
--       vim.keymap.set("n", "<C-space>", rust_tools.hover_actions.hover_actions, { buffer = bufnr })
--       -- Code action groups
--       vim.keymap.set("n", "<Leader>a", rust_tools.code_action_group.code_action_group, { buffer = bufnr })
--       -- -- DAP :lua require('dap').continue() keymap
--       -- vim.keymap.set("n", "<Leader>dc", rust_tools.dap_continue.continue, { buffer = bufnr })
--     end,
--     standalone = false,
--     hover_actions = {
--       auto_focus = true,
--     },
--     server = {
--       settings = {
--         ["rust-analyzer"] = {
--           checkOnSave = {
--             command = "clippy"
--           }
--         }
--       },
--     },
--   }
-- })

-- rust_tools.runnables.runnables()
-- rust_tools.hover_actions.hover_actions()
-- rust_tools.parent_module.parent_module()

-- local map = vim.keymap.set
-- local opts = { noremap = true, silent = true }
-- -- Command:
-- -- RustMoveItemUp
-- -- RustMoveItemDown
-- map('n', '<Leader>ru', '<cmd>RustMoveItemUp<CR>', opts)
-- map('n', '<Leader>rd', '<cmd>RustMoveItemDown<CR>', opts)


require('crates').setup {
  smart_insert = true,
  insert_closing_quote = true,
  autoload = true,
  autoupdate = true,
  autoupdate_throttle = 250,
  loading_indicator = true,
  date_format = "%Y-%m-%d",
  thousands_separator = ".",
  notification_title = "Crates",
  curl_args = { "-sL", "--retry", "1" },
  max_parallel_requests = 80,
  expand_crate_moves_cursor = true,
  enable_update_available_warning = true,
  text = {
    loading = "   Loading",
    version = "   %s",
    prerelease = "   %s",
    yanked = "   %s",
    nomatch = "   No match",
    upgrade = "   %s",
    error = "   Error fetching crate",
  },
  highlight = {
    loading = "CratesNvimLoading",
    version = "CratesNvimVersion",
    prerelease = "CratesNvimPreRelease",
    yanked = "CratesNvimYanked",
    nomatch = "CratesNvimNoMatch",
    upgrade = "CratesNvimUpgrade",
    error = "CratesNvimError",
  },
  popup = {
    autofocus = false,
    hide_on_select = false,
    copy_register = '"',
    style = "minimal",
    border = "none",
    show_version_date = false,
    show_dependency_version = true,
    max_height = 30,
    min_width = 20,
    padding = 1,
    text = {
      title = " %s",
      pill_left = "",
      pill_right = "",
      description = "%s",
      created_label = " created        ",
      created = "%s",
      updated_label = " updated        ",
      updated = "%s",
      downloads_label = " downloads      ",
      downloads = "%s",
      homepage_label = " homepage       ",
      homepage = "%s",
      repository_label = " repository     ",
      repository = "%s",
      documentation_label = " documentation  ",
      documentation = "%s",
      crates_io_label = " crates.io      ",
      crates_io = "%s",
      categories_label = " categories     ",
      keywords_label = " keywords       ",
      version = "  %s",
      prerelease = " %s",
      yanked = " %s",
      version_date = "  %s",
      feature = "  %s",
      enabled = " %s",
      transitive = " %s",
      normal_dependencies_title = " Dependencies",
      build_dependencies_title = " Build dependencies",
      dev_dependencies_title = " Dev dependencies",
      dependency = "  %s",
      optional = " %s",
      dependency_version = "  %s",
      loading = "  ",
    },
    highlight = {
      title = "CratesNvimPopupTitle",
      pill_text = "CratesNvimPopupPillText",
      pill_border = "CratesNvimPopupPillBorder",
      description = "CratesNvimPopupDescription",
      created_label = "CratesNvimPopupLabel",
      created = "CratesNvimPopupValue",
      updated_label = "CratesNvimPopupLabel",
      updated = "CratesNvimPopupValue",
      downloads_label = "CratesNvimPopupLabel",
      downloads = "CratesNvimPopupValue",
      homepage_label = "CratesNvimPopupLabel",
      homepage = "CratesNvimPopupUrl",
      repository_label = "CratesNvimPopupLabel",
      repository = "CratesNvimPopupUrl",
      documentation_label = "CratesNvimPopupLabel",
      documentation = "CratesNvimPopupUrl",
      crates_io_label = "CratesNvimPopupLabel",
      crates_io = "CratesNvimPopupUrl",
      categories_label = "CratesNvimPopupLabel",
      keywords_label = "CratesNvimPopupLabel",
      version = "CratesNvimPopupVersion",
      prerelease = "CratesNvimPopupPreRelease",
      yanked = "CratesNvimPopupYanked",
      version_date = "CratesNvimPopupVersionDate",
      feature = "CratesNvimPopupFeature",
      enabled = "CratesNvimPopupEnabled",
      transitive = "CratesNvimPopupTransitive",
      normal_dependencies_title = "CratesNvimPopupNormalDependenciesTitle",
      build_dependencies_title = "CratesNvimPopupBuildDependenciesTitle",
      dev_dependencies_title = "CratesNvimPopupDevDependenciesTitle",
      dependency = "CratesNvimPopupDependency",
      optional = "CratesNvimPopupOptional",
      dependency_version = "CratesNvimPopupDependencyVersion",
      loading = "CratesNvimPopupLoading",
    },
    keys = {
      hide = { "q", "<esc>" },
      open_url = { "<cr>" },
      select = { "<cr>" },
      select_alt = { "s" },
      toggle_feature = { "<cr>" },
      copy_value = { "yy" },
      goto_item = { "gd", "K", "<C-LeftMouse>" },
      jump_forward = { "<c-i>" },
      jump_back = { "<c-o>", "<C-RightMouse>" },
    },
  },
  -- null_ls = {
  --   enabled = false,
  --   name = "Crates",
  -- },
  on_attach = function(bufnr) end,
}

local function show_documentation()
  local filetype = vim.bo.filetype
  if vim.tbl_contains({ 'vim', 'help' }, filetype) then
    vim.cmd('h ' .. vim.fn.expand('<cword>'))
  elseif vim.tbl_contains({ 'man' }, filetype) then
    vim.cmd('Man ' .. vim.fn.expand('<cword>'))
  elseif vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
    require('crates').show_popup()
  else
    vim.lsp.buf.hover()
  end
end

vim.keymap.set('n', 'K', show_documentation, { silent = true })

-- init doc key
-- {'n'} <C-space> hover_actions()
-- {'n'} <Leader>a code_action_group()
-- end doc key
