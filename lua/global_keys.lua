-- Thanks to Primeagen for most of this keybindings
-- https://github.com/ThePrimeagen/init.lua

-- Config substitute keybindings
vim.api.nvim_set_keymap('n', '<Leader>ss', ':%s//g<Left><Left>', { noremap = true, silent = true })

-- Fast substitution
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Move selected line / block of text in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Move above line to final current line
vim.keymap.set("n", "J", "mzJ`z")

-- Up / Down page cursor movement to keep cursor in middle of screen
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Move to next / previous search result
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste yanked text
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Yank to end of line and copy to system clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete the current char above the cursor
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz") -- Move to next quickfix item
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz") -- Move to previous quickfix item
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz") -- Move to next location list item
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz") -- Move to previous location list item

-- Set file to executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)


