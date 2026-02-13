-- local nvim_lsp = require('lspconfig')
-- local util = require('lspconfig/util')
local util = require('lspconfig.util')

vim.lsp.config['jdtls'] = {
    cmd = { "jdtls" },
    filetypes = { "java" },
    root_dir = util.root_pattern("pom.xml", "gradle.build", ".git"),
}
vim.lsp.enable('jdtls')
