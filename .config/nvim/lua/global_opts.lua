vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/undodir"

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

vim.opt.updatetime = 50

vim.opt.signcolumn = "yes"

vim.opt.clipboard = "unnamedplus"

vim.opt.cursorline = true
vim.opt.cursorcolumn = true

vim.opt.virtualedit = "onemore"

-- Change color and font StatusLine
-- vim.cmd [[
-- highlight StatusLine guibg=Green guifg=White gui=bold
-- ]]

-- force vim cmd
vim.cmd [[
autocmd BufWinEnter * highlight StatusLine guibg=Green guifg=White gui=bold
]]

-- keys to wrap lines
vim.opt.whichwrap = "b,s,<,>,[,],h,l"
