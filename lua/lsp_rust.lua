-- Configure Rust Analyzer
local nvim_lsp = require('lspconfig')
nvim_lsp.rust_analyzer.setup {}

local rust_tools = require('rust-tools')
rust_tools.setup({
    server = {
        on_attach = function(client, bufnr)
            vim.keymap.set('n', '<leader>ba', rust_tools.hover_actions.hover_actions, { buffer = bufnr })
        end
    }
})


-- init doc key
-- {'n'} <leader>ba = Hover actions
-- end doc key
