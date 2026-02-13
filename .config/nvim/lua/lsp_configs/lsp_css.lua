-- Config lsp for css
-- local lspconfig = require('lspconfig')

-- Config for css lsp
vim.lsp.config['cssls'] = {
    cmd = { "css-lsp", "--stdio" },
    filetypes = { "css", "scss", "less" },
    settings = {
        css = {
            validate = true,
        },
        less = {
            validate = true,
        },
        scss = {
            validate = true,
        },
    },
}
vim.lsp.enable('cssls')
