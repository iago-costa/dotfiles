local on_attach = require('plugins.configs.lspconfig').on_attach
local capabilities = require('plugins.configs.lspconfig').capabilities

local nvim_lsp = require('lspconfig')
local util = require('lspconfig/util')

nvim_lsp.jdtls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "jdtls" },
    filetypes = { "java" },
    root_dir = util.root_pattern("pom.xml", "gradle.build", ".git"),
}
