local nvim_lsp = require('lspconfig')

-- Configure Pyright for Python
nvim_lsp.pyright.setup{

}

-- Configure pylsp for Python
nvim_lsp.pylsp.setup{
    cmd = {"pylsp"},
    filetypes = {"python"},
    settings = {
        pylsp = {
            plugins = {
                pylint = {
                    enabled = true,
                    executable = "pylint",
                },
                pyflakes = {
                    enabled = true,
                    executable = "pyflakes",
                    args = {}
                },
            },
        },
    },
}



