
local start_marker_name = "init doc key"
local end_marker_name = "end doc key"

-- import from lua file in same directory
local documentation_keymap_nvim = require("doc_keymap_nvim")

documentation_keymap_nvim.setup ({
    start_marker_name = start_marker_name,
    start_marker = "%-%- " .. start_marker_name,
    end_marker_name = end_marker_name,
    end_marker = "%-%- " .. end_marker_name,
    special_doc_separator = "=",
    keymap_win_buffer_name = "float_bufnr",
    doc_win_buffer_name = "float_bufnr2",
    filter_win_buffer_name = "float_bufnr3",
    path_files_lua = ".config/nvim/lua",
})
