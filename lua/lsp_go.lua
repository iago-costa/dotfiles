

local nvim_lsp = require('lspconfig')

nvim_lsp.gopls.setup {
    cmd = {"gopls", "serve"},
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            hints = {
                -- Show hint when you have a variable that could be declared with a
                -- shorter type
                typeparams = true,
            },
            staticcheck = true,
        },
    },
}
