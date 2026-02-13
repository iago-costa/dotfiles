-- Config for javascript lsp
-- local lspconfig = require('lspconfig')
local util = require('lspconfig.util')

-- Config for eslint lsp
vim.lsp.config['eslint'] = {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_dir = util.root_pattern(".git"),
}
vim.lsp.enable('eslint')

-- Config for typescript lsp
vim.lsp.config['ts_ls'] = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
}
vim.lsp.enable('ts_ls')

-- Config for html lsp
vim.lsp.config['html'] = {
  cmd = { "html-lsp", "--stdio" },
  filetypes = { "html" },
  root_dir = util.root_pattern(".git"),
}
vim.lsp.enable('html')

-- Config for json lsp
vim.lsp.config['jsonls'] = {
  cmd = { "json-lsp", "--stdio" },
  filetypes = { "json" },
  root_dir = util.root_pattern(".git"),
}
vim.lsp.enable('jsonls')
