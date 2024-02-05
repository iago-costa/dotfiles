local nvim_lsp = require('lspconfig')
local util = require('lspconfig/util')

nvim_lsp.jdtls.setup {
    cmd = { "jdtls" },
    filetypes = { "java" },
    root_dir = util.root_pattern("pom.xml", "gradle.build", ".git"),
}
