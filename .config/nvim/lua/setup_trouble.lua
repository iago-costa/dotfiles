vim.keymap.set("n", "xq", "<cmd>TroubleToggle quickfix<cr>",
    { silent = true, noremap = true }
)

vim.keymap.set("n", "xl", "<cmd>TroubleToggle loclist<cr>",
    { silent = true, noremap = true }
)

vim.keymap.set("n", "xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
    { silent = true, noremap = true }
)

vim.keymap.set("n", "xd", "<cmd>TroubleToggle document_diagnostics<cr>",
    { silent = true, noremap = true }
)

vim.keymap.set("n", "xr", function() require("trouble").toggle("lsp_references") end)



-- init doc key
-- {'n'} xq = toggle quickfix
-- {'n'} xl = toggle loclist
-- {'n'} xw = toggle lsp workspace diagnostics
-- {'n'} xd = toggle lsp document diagnostics
-- {'n'} xr = toggle lsp references
-- end doc key
