
-- Config substitute keybindings
vim.api.nvim_set_keymap('n', '<Leader>ss', ':%s//g<Left><Left>', { noremap = true, silent = true })

vim.keymap.set({"n", "v"}, "<leader>sa", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Fast substitution

vim.keymap.set({"n", "v"}, "<leader>sb", [[:.,$s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Fast substitution only below cursor

vim.keymap.set({"n", "v"}, "<leader>sa", [[:.,$s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Fast substitution only above cursor

vim.keymap.set({"n", "v"}, "<leader>sr", [[:'<,'>s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Fast substitution in range of lines

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- Move selected line / block of text up
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- Move selected line / block of text down

vim.keymap.set("n", "J", "mzJ`z") -- Jump to above line in relational to current line
vim.keymap.set("n", "K", "mzJ`z") -- Jump to below line in relational to current line

vim.keymap.set("n", "<C-u>", "<C-u>zz") -- UP page cursor movement to keep cursor in middle of screen
vim.keymap.set("n", "<c-d>", "<c-d>zz") -- Down page cursor movement to keep cursor in middle of screen

vim.keymap.set("n", "f", "fzz") -- Jump to char n in current line forward
vim.keymap.set("n", "F", "Fzz") -- Jump to char n in current line backwards

vim.keymap.set("n", "n", "nzzzv") -- Move to next / previous search result
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]]) -- Paste yanked text

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]]) -- Yank to end of line and copy to system clipboard
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]]) -- Delete the current char above the cursor

vim.keymap.set("i", "<C-c>", "<Esc>") -- This is going to get me cancelled

vim.keymap.set("n", "Q", "<nop>") -- Disable Ex mode
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format) -- Format current buffer

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz") -- Move to next quickfix item
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz") -- Move to previous quickfix item
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz") -- Move to next location list item
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz") -- Move to previous location list item

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }) -- Set file to executable

vim.keymap.set("v", "<S-Tab>", "<gv") -- Tab and Untab in visual mode (useful for block of text)
vim.keymap.set("v", "<Tab>", ">gv")

vim.keymap.set("n", "<C-Tab>", "<C-w>w") -- Change window focus

-- Split only the cursor for multiple cursors in insert mode using <C-S>down key and <C-S>up key
-- vim.keymap.set("i", "<C-S-Down>", "<C-O>o")
-- vim.keymap.set("i", "<C-S-Up>", "<C-O>O")

vim.keymap.set("n", "<leader>wh", "<cmd>split<CR>") -- Split window horizontally
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<CR>") -- Split window vertically

vim.keymap.set("n", "<leader><leader>", "<cmd>LoadDoc<CR>") -- Execute named command :LoadDoc

vim.keymap.set("n", "<Enter>", "o<Esc>") -- <Enter> in normal mode insert a new line above the cursor and move cursor to new line

vim.keymap.set("n", "<Backspace>", function() -- <Backspace> in normal mode delete the current line and move cursor to the line above
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! k")
    vim.cmd("normal! dd")
    vim.api.nvim_win_set_cursor(0, {current_line - 1, 0})
end)



-- init doc key
-- {'n'} <Leader>ss : substitute word under cursor 
-- {'n', 'v'} <Leader>sa : substitute word under cursor in whole file
-- {'n', 'v'} <Leader>sb : substitute word under cursor in whole file below cursor
-- {'n', 'v'} <Leader>sa : substitute word under cursor in whole file above cursor
-- {'n', 'v'} <Leader>sr : substitute word under cursor in range of lines
-- {'v'} J : move selected line / block of text down
-- {'v'} K : move selected line / block of text up
-- {'n'} J : move cursor to above line
-- {'n'} K : move cursor to below line
-- {'n'} <C-u> : move cursor up page
-- {'n'} <C-d> : move cursor down page
-- {'n'} f : jump to char n in current line forward
-- {'n'} F : jump to char n in current line backwards
-- {'n'} n : move to next search result
-- {'n'} N : move to previous search result
-- {'x'} <Leader>p : paste yanked text
-- {'n', 'v'} <Leader>y : yank to end of line and copy to system clipboard
-- {'n'} <Leader>Y : yank to end of line and copy to system clipboard
-- {'n', 'v'} <Leader>d : delete the current char above the cursor
-- {'i'} <C-c> : exit insert mode
-- {'n'} Q : disable Ex mode
-- {'n'} <Leader>f : format current buffer
-- {'n'} <C-k> : move to next quickfix item
-- {'n'} <C-j> : move to previous quickfix item
-- {'n'} <Leader>k : move to next location list item
-- {'n'} <Leader>j : move to previous location list item
-- {'n'} <Leader>x : set file to executable
-- {'v'} <S-Tab> : tab and untab in visual mode
-- {'v'} <Tab> : tab and untab in visual mode
-- {'n'} <Leader>wh : split window horizontally
-- {'n'} <Leader>wv : split window vertically
-- {'n'} <Leader><Leader> : execute named command LoadDoc
-- {'n'} <Enter> : insert a new line above the cursor and move cursor to new line
-- {'n'} <Backspace> : delete the current line and move cursor to the line above
-- end doc key

