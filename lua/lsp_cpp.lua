

-- local nvim_lsp = require('lspconfig')
-- local DATA_PATH = vim.fn.stdpath('data')
-- -- config lsp to cpp language
-- nvim_lsp.clangd.setup {
--     cmd = {DATA_PATH .. "/lspinstall/cpp/clangd/bin/clangd"},
--     on_attach = require'lsp'.common_on_attach,
--     capabilities = require'lsp'.capabilities,
--     filetypes = {"c", "cpp", "objc", "objcpp"},
--     init_options = {
--         clangdFileStatus = true,
--         usePlaceholders = true,
--         completeUnimported = true,
--         semanticHighlighting = true
--     }
-- }
