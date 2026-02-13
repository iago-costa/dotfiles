-- Config for lua lsp
-- local lspconfig = require('lspconfig')

-- Config for lua lsp
vim.lsp.config['lua_ls'] = {
    cmd = { "lua-language-server" },
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                },
            },
        },
    },
}
vim.lsp.enable('lua_ls')
