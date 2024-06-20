-- Config for javascript lsp
local lspconfig = require('lspconfig')

-- Config for eslint lsp
lspconfig.eslint.setup {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_dir = lspconfig.util.root_pattern(".git"),
}

-- Config for typescript lsp
lspconfig.tsserver.setup {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
}

-- Config for html lsp
lspconfig.html.setup {
  cmd = { "html-lsp", "--stdio" },
  filetypes = { "html" },
  root_dir = lspconfig.util.root_pattern(".git"),
}

-- Config for json lsp
lspconfig.jsonls.setup {
  cmd = { "json-lsp", "--stdio" },
  filetypes = { "json" },
  root_dir = lspconfig.util.root_pattern(".git"),
}
