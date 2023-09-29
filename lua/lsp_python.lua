local nvim_lsp = require('lspconfig')

-- Configure Pyright for Python
nvim_lsp.pyright.setup {
    cmd = { "pyright" },
    filetypes = { "python" },
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
                stubPath = "/home/gup/.local/share/nvim/lspinstall/python/node_modules/pyright-stdlib"
            }
        }
    }
}


-- Configure pylama for pyright


-- Configure pylsp for Python
nvim_lsp.pylsp.setup{
    cmd = {"pylsp"},
    filetypes = {"python"},
    settings = {
        pylsp = {
            plugins = {
                -- pylint = {
                --     enabled = true,
                --     executable = "pylint",
                -- },
                -- pyflakes = {
                --     enabled = true,
                --     executable = "pyflakes",
                --     args = {}
                -- },
                pylama = {
                    enabled = true,
                    executable = "pylama",
                    args = {}
                },
            },
        },
    },
}
