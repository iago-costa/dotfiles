-- Set log level to debug for LSP
vim.lsp.set_log_level("debug")

-- Specify the directory for plugins (optional, but recommended)
vim.cmd [[packadd packer.nvim]]

-- Highlight matching words under cursor
vim.cmd [[
highlight MatchWord cterm=underline gui=underline
]]

-- -- AutoFormat
Pattern = "*.rs, *.lua, *.py, *.js, *.css, *.go, *.yaml, *.yml, *.html, *.clj, *.cpp, *.c, *.h, *.hpp, *.json, *.md"

-- Set up an autocmd for BufWrite for multiple file types
-- autocmd BufWritePre <buffer> lua vim.defer_fn(function() vim.lsp.buf.format() end, 3000)
vim.api.nvim_exec([[
    augroup FormatOnSave
        autocmd!
        autocmd BufWritePre <buffer> lua vim.lsp.buf.format()
    augroup END
]], true)
