-- Set log level to debug for LSP
vim.lsp.set_log_level("debug")

-- Specify the directory for plugins (optional, but recommended)
vim.cmd [[packadd packer.nvim]]

-- Highlight matching words under cursor
vim.cmd [[
highlight MatchWord cterm=underline gui=underline
]]

-- AutoFormat
local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = [[*.rs, *.lua, *.py, *.js, *.css]],
	callback = function()
		vim.lsp.buf.format({ timeout_ms = 200 })
	end,
	group = format_sync_grp,
})

