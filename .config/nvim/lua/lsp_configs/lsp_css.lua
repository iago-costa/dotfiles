-- Config lsp for css
local lspconfig = require('lspconfig')

-- Config for css lsp
lspconfig.cssls.setup {
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
