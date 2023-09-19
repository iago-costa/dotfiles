-- Setup lsp-zero
local lsp_zero = require('lsp-zero')

-- Setup lsp-zero keymaps
lsp_zero.on_attach(function(client, bufnr)
    local opts = { noremap=true, buffer=bufnr }
    local map = vim.keymap.set
    map('n', 'bd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    map('n', 'bD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    map('n', 'br', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    map('i', '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    map('n', 'bi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    map('n', 'bh', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    map('n', 'bf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
    map('n', 'ba', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
end)
