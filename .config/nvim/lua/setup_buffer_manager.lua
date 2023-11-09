-- Setup to barbar.nvim
-- local map = vim.keymap.set
-- local opts = { noremap = true, silent = true }

-- -- Move to previous/next
-- map('n', '<C-S-Left>', '<Cmd>BufferPrevious<CR>', opts)
-- map('n', '<C-S-Right>', '<Cmd>BufferNext<CR>', opts)

-- -- Goto buffer in position...
-- map('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', opts)
-- map('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', opts)
-- map('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', opts)
-- map('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', opts)
-- map('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', opts)
-- map('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', opts)
-- map('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', opts)
-- map('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', opts)
-- map('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', opts)
-- map('n', '<A-0>', '<Cmd>BufferLast<CR>', opts)

-- -- Close buffer
-- map('n', '<Leader>bq', '<Cmd>BufferClose<CR>', opts)
-- map('n', '<Leader>bqa', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>', opts)

-- -- Magic buffer-picking mode
-- map('n', '<Leader>bp', '<Cmd>BufferPick<CR>', opts)

-- -- Sort automatically by...
-- map('n', '<Space>bb', '<Cmd>BufferOrderByBufferNumber<CR>', opts)
-- map('n', '<Space>bd', '<Cmd>BufferOrderByDirectory<CR>', opts)
-- map('n', '<Space>bl', '<Cmd>BufferOrderByLanguage<CR>', opts)
-- map('n', '<Space>bw', '<Cmd>BufferOrderByWindowNumber<CR>', opts)


-- -- init doc key
-- -- {'n'} <C-S-Left>     =  * <Cmd>BufferPrevious<CR>
-- -- {'n'} <C-S-Right>    =  * <Cmd>BufferNext<CR>
-- -- {'n'} <A-1>          =  * <Cmd>BufferGoto 1<CR>
-- -- {'n'} <A-2>          =  * <Cmd>BufferGoto 2<CR>
-- -- {'n'} <A-3>          =  * <Cmd>BufferGoto 3<CR>
-- -- {'n'} <A-4>          =  * <Cmd>BufferGoto 4<CR>
-- -- {'n'} <A-5>          =  * <Cmd>BufferGoto 5<CR>
-- -- {'n'} <A-6>          =  * <Cmd>BufferGoto 6<CR>
-- -- {'n'} <A-7>          =  * <Cmd>BufferGoto 7<CR>
-- -- {'n'} <A-8>          =  * <Cmd>BufferGoto 8<CR>
-- -- {'n'} <A-9>          =  * <Cmd>BufferGoto 9<CR>
-- -- {'n'} <A-0>          =  * <Cmd>BufferLast<CR>
-- -- {'n'} <Leader>bq     =  * <Cmd>BufferClose<CR>
-- -- {'n'} <Leader>bqa    =  * <Cmd>BufferCloseAllButCurrentOrPinned<CR>
-- -- {'n'} <Leader>bp     =  * <Cmd>BufferPick<CR>
-- -- {'n'} <Space>bb      =  * <Cmd>BufferOrderByBufferNumber<CR>
-- -- {'n'} <Space>bd      =  * <Cmd>BufferOrderByDirectory<CR>
-- -- {'n'} <Space>bl      =  * <Cmd>BufferOrderByLanguage<CR>
-- -- {'n'} <Space>bw      =  * <Cmd>BufferOrderByWindowNumber<CR>
-- -- end doc key
--
--
--
--
--
-- Setup to buffer_manager.nvim
--
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
map('n', 'bm', '<Cmd>lua require("buffer_manager.ui").toggle_quick_menu()<CR>', opts)
map('n', 'bn', '<Cmd>lua require("buffer_manager.ui").nav_next()<CR>', opts)
map('n', 'bp', '<Cmd>lua require("buffer_manager.ui").nav_prev()<CR>', opts)

vim.api.nvim_set_hl(0, "BufferManagerModified", { fg = "Orange" })

-- Setup
require("buffer_manager").setup({
    select_menu_item_commands = {
        v = {
            key = "<C-v>",
            command = "vsplit"
        },
        h = {
            key = "<C-h>",
            command = "split"
        }
    },
    focus_alternate_buffer = false,
    short_file_names = false,
    short_term_names = false,
    loop_nav = false,
})

-- Navigate buffers bypassing the menu
local bmui = require("buffer_manager.ui")
local keys = '1234567890'
for i = 1, #keys do
    local key = keys:sub(i, i)
    map(
        'n',
        string.format('<leader>%s', key),
        function() bmui.nav_file(i) end,
        opts
    )
end

-- Opem menu and search
map({ 't', 'n' }, '<M-m>', function()
    bmui.toggle_quick_menu()
    -- wait for the menu to open
    vim.defer_fn(function()
        vim.fn.feedkeys('/')
    end, 50)
end, opts)

-- Reorder buffers in menu
-- vim.api.nvim_command([[
-- autocmd FileType buffer_manager vnoremap J :m '>+1<CR>gv=gv
-- autocmd FileType buffer_manager vnoremap K :m '<-2<CR>gv=gv
-- ]])


-- init doc key
-- {'n'} bm = * <Cmd>lua require("buffer_manager.ui").toggle_quick_menu()<CR>
-- {'n'} bn =  * <Cmd>lua require("buffer_manager.ui").nav_next()<CR>
-- {'n'} bp =  * <Cmd>lua require("buffer_manager.ui").nav_prev()<CR>
-- {'n'} <leader>number =  * <Cmd>lua require("buffer_manager.ui").nav_file(number)<CR>
-- {'t', 'n'} <M-m> =  * <Cmd>lua require("buffer_manager.ui").toggle_quick_menu()<CR>
-- end doc key
