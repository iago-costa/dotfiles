local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Add file to harpoon
vim.keymap.set("n", "<C-a>", mark.add_file)

-- Toggle quick menu
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

-- Clear file from harpoon
vim.keymap.set("n", "<C-x>", mark.rm_file)

-- Clear all marks
vim.keymap.set("n", "<C-z>", mark.clear_all)



