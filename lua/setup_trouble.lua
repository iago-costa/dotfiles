vim.keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",
  {silent = true, noremap = true}
)

vim.keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>",
  {silent = true, noremap = true}
)

vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
  {silent = true, noremap = true}
)

vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",
  {silent = true, noremap = true}
)

-- init doc key
-- {'n'} <leader>xq = toggle quickfix
-- {'n'} <leader>xl = toggle loclist
-- {'n'} <leader>xw = toggle lsp workspace diagnostics
-- {'n'} <leader>xd = toggle lsp document diagnostics
-- end doc key
