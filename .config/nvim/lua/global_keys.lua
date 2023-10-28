-- Config substitute keybindings
vim.api.nvim_set_keymap('n', '<Leader>ss', ':%s//g<Left><Left>', { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])      -- Fast substitution

vim.keymap.set({ "n", "v" }, "<leader>sb", [[:.,$s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])   -- Fast substitution only below cursor

vim.keymap.set({ "n", "v" }, "<leader>sa", [[:.,$s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])   -- Fast substitution only above cursor

vim.keymap.set({ "n", "v" }, "<leader>sr", [[:+4,-4s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Fast substitution in range of lines

vim.keymap.set("v", "<M-Down>", ":m '>+1<CR>gv=gv")                                                    -- Move selected line / block of text down
vim.keymap.set("v", "<M-Up>", ":m '<-2<CR>gv=gv")                                                      -- Move selected line / block of text up
vim.keymap.set("i", "<M-Up>", "<Esc>:m .-2<CR>==gi")                                                   -- Move line to up in insert mode
vim.keymap.set("i", "<M-Down>", "<Esc>:m .+1<CR>==gi")                                                 -- Move line to down in insert mode
vim.keymap.set("n", "<M-Up>", ":m .-2<CR><Esc>")                                                       -- Move line to up in normal mode
vim.keymap.set("n", "<M-Down>", ":m .+1<CR><Esc>")                                                     -- Move line to down in normal mode

vim.keymap.set("n", "J", "mzJ`z")                                                                      -- Jump to above line in relational to current line
vim.keymap.set("n", "K", "mzJ`z")                                                                      -- Jump to below line in relational to current line

vim.keymap.set("n", "<S-C-Up>", "<C-u>zz")                                                             -- UP page cursor movement to keep cursor in middle of screen
vim.keymap.set("n", "<S-C-Down>", "<c-d>zz")                                                           -- Down page cursor movement to keep cursor in middle of screen

vim.keymap.set("n", "f", "f")                                                                          -- Jump to char n in current line forward
vim.keymap.set("n", "F", "F")                                                                          -- Jump to char n in current line backwards

vim.keymap.set("n", "n", "nzzzv")                                                                      -- Move to next search result
vim.keymap.set("n", "N", "Nzzzv")                                                                      -- Move to previous search result

vim.keymap.set("x", "<leader>p", [["_dP]])                                                             -- Paste yanked text

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])                                                     -- Yank to end of line and copy to system clipboard
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]]) -- Delete the current char above the cursor

-- Cut line in insert mode
vim.keymap.set("i", "<C-x>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! ^")
    vim.cmd("normal! v$")
    vim.cmd("normal! d")
    vim.api.nvim_win_set_cursor(0, { line, 0 })
end)

vim.keymap.set("i", "<C-c>", "<Esc>")                                       -- This is going to get me cancelled

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")                            -- Move to next quickfix item
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")                            -- Move to previous quickfix item
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")                        -- Move to next location list item
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")                        -- Move to previous location list item

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }) -- Set file to executable

vim.keymap.set("v", "<S-Tab>", "<gv")                                       -- Untab in visual mode
vim.keymap.set("v", "<Tab>", ">gv")                                         -- Tab in visual mode

vim.keymap.set("n", "<Tab>", function()                                     -- Tab in normal mode
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! >>")
    vim.api.nvim_win_set_cursor(0, { line, vim.api.nvim_win_get_cursor(0)[2] + 4 })
end)

vim.keymap.set("n", "<S-Tab>", function() -- Untab in normal mode
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! <<")
    vim.api.nvim_win_set_cursor(0, { line, vim.api.nvim_win_get_cursor(0)[2] - 4 })
end)

vim.keymap.set("i", "<S-Tab>", function() -- Untab in insert mode
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.cmd("normal! <<")
    vim.api.nvim_win_set_cursor(0, { line, vim.api.nvim_win_get_cursor(0)[2] - 4 })
end)

-- Define the FocusNextWindow and FocusPreviousWindow commands
vim.cmd([[
  command! FocusNextWindow lua focus_next_window()
  command! FocusPreviousWindow lua focus_previous_window()
]])

-- Lua function to focus on the next window in a loop
function focus_next_window()
    local current_win = vim.fn.winnr()
    local total_wins = vim.fn.winnr('$')
    local next_win = current_win + 1

    if next_win > total_wins then
        next_win = 1
    end

    vim.cmd(next_win .. 'wincmd w')
end

-- Lua function to focus on the previous window in a loop
function focus_previous_window()
    local current_win = vim.fn.winnr()
    local total_wins = vim.fn.winnr('$')
    local previous_win = current_win - 1

    if previous_win < 1 then
        previous_win = total_wins
    end

    vim.cmd(previous_win .. 'wincmd w')
end

vim.api.nvim_set_keymap('n', '<S-M-Right>', ':FocusNextWindow<CR>', { noremap = true, silent = true }) -- Define keymap for FocusNextWindow
vim.api.nvim_set_keymap('n', '<S-M-Left>', ':FocusPreviousWindow<CR>', { noremap = true, silent = true })

vim.keymap.set("n", "<leader>wh", "<cmd>split<CR>")             -- Split window horizontally
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<CR>")            -- Split window vertically

vim.keymap.set("n", "<leader>m", "<cmd>ToggleLoadDocFiles<CR>") -- Execute named command :TogleLoadDocFiles
vim.keymap.set("n", "<leader>mg", "<cmd>ToggleLoadDocGrep<CR>") -- Execute named command :TogleLoadDocGrep

vim.keymap.set("n", "<Enter>", "o<Esc>")                        -- <Enter> in normal mode insert a new line above the cursor and move cursor to new line

-- vim.keymap.set("n", "<Backspace>",
--     function() -- <Backspace> in normal mode delete the current line and move cursor to the line above
--         vim.cmd("normal! k")
--         vim.cmd("normal! dd")
--     end)

vim.keymap.set({ "n" }, "<C-a>", "ggVG")          -- <C-a> Select all text in visual mode and normal mode

vim.keymap.set("n", "<leader>q", "<cmd>only<CR>") -- kill all windows except current
vim.keymap.set("n", "<leader>Q", "<cmd>qa<CR>")   -- kill all windows

vim.keymap.set("n", "<leader>wq", "<cmd>wq<CR>")  -- kill current window


-- init doc key
-- {'n'} <Leader>ss = substitute word under cursor
-- {'n', 'v'} <Leader>s = substitute word under cursor in all file
-- {'n', 'v'} <Leader>sb = substitute word under cursor in file below cursor
-- {'n', 'v'} <Leader>sa = substitute word under cursor in file above cursor
-- {'n', 'v'} <Leader>sr = substitute word under cursor in range of lines
-- {'v', 'n', 'i'} <M-Down> = move selected line / block of text down
-- {'v', 'n', 'i'} <M-Up> = move selected line / block of text up
-- {'n'} J = jump to above line in relational to current line
-- {'n'} K = jump to below line in relational to current line
-- {'n'} <S-C-Up> = up page cursor movement to keep cursor in middle of screen
-- {'n'} <S-C-Down> = down page cursor movement to keep cursor in middle of screen
-- {'n'} f = jump to char n in current line forward
-- {'n'} F = jump to char n in current line backwards
-- {'n'} n = move to next search result
-- {'n'} N = move to previous search result
-- {'x'} <leader>p = paste yanked text
-- {'n', 'v'} <leader>y = yank to end of line and copy to system clipboard
-- {'n'} <leader>Y = yank to end of line and copy to system clipboard
-- {'n', 'v'} <leader>d = delete the current char above the cursor
-- {'i'} <C-x> = cut line in insert mode
-- {'i'} <C-c> = this is going to get me cancelled
-- {'n'} Q = disable Ex mode
-- {'n'} <C-k> = move to next quickfix item
-- {'n'} <C-j> = move to previous quickfix item
-- {'n'} <leader>k = move to next location list item
-- {'n'} <leader>j = move to previous location list item
-- {'n'} <leader>x = set file to executable
-- {'v', 'n', 'i'} <S-Tab> = untab in visual mode
-- {'v', 'n', 'i'} <Tab> = tab in visual mode
-- <S-M-Right> = focus next window M=Alt
-- <S-M-Left> = focus previous window M=Alt
-- {'n'} <leader>wh = split window horizontally
-- {'n'} <leader>wv = split window vertically
-- {'n'} <leader>m = execute named command :TogleLoadDoc
-- {'n'} <Enter> = <Enter> in normal mode insert a new line above the cursor and move cursor to new line
-- {'n'} <Backspace> = <Backspace> (disabled) in normal mode delete the current line and move cursor to the line above
-- {'n', 'v'} <C-a> = <C-a> Select all text in visual mode and normal mode
-- {'n'} <leader>q = kill all windows except current
-- {'n'} <leader>Q = kill all windows
-- {'n'} <leader>wq = kill current window
-- end doc key
