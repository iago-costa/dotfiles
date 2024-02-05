local nvim_lsp = require('lspconfig')
local util = require('lspconfig/util')

nvim_lsp.gopls.setup {
    cmd = { "gopls" },
    settings = {
        gopls = {
            completeUnimported = true,
            usePlaceholders = true,
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
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = util.root_pattern("go.mod", ".git", "go.work"),
}
