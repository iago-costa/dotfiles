local M = {
  "mfussenegger/nvim-dap",
  event = "VeryLazy",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope-dap.nvim",
    },
  },
  dap = {
    plugin = true,
    n = {
      ["<leader>dT"] = {
        "<cmd> DapToggleBreakpoint<CR>",
        "Add/Remove breakpoint",
      },
      ["<leader>dS"] = {
        function()
          local widgets = require("dap.ui.widgets");
          local sidebar = widgets.sidebar(widgets.scopes);
          sidebar.open();
        end,
        "Open debug sidebar",
      },
    },
  },
  dap_go = {
    plugin = true,
    n = {
      ["<leader>dgt"] = {
        function()
          require("dap-go").debug_test();
        end,
        "Debug go test",
      },
      ["<leader>dgl"] = {
        function()
          require("dap-go").debug_last();
        end,
        "Debug last go test",
      }
    },
  }
}

-- function M.config()
--   local wk = require "coding.which_key"
--   wk.register {
--     ["<leader>dt"] = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
--     ["<leader>db"] = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
--     ["<leader>dc"] = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
--     ["<leader>dC"] = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
--     ["<leader>dd"] = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
--     ["<leader>dg"] = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
--     ["<leader>di"] = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
--     ["<leader>do"] = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
--     ["<leader>du"] = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
--     ["<leader>dp"] = { "<cmd>lua require'dap'.pause()<cr>", "Pause" },
--     ["<leader>dr"] = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
--     ["<leader>ds"] = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
--     ["<leader>dq"] = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
--     ["<leader>dU"] = { "<cmd>lua require'dapui'.toggle({reset = true})<cr>", "Toggle UI" },
--   }
-- end

vim.keymap.set("n", "<leader>dtr", "<cmd>lua require'dap'.run()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dt", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>db", "<cmd>lua require'dap'.step_back()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dC", "<cmd>lua require'dap'.run_to_cursor()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dd", "<cmd>lua require'dap'.disconnect()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dg", "<cmd>lua require'dap'.session()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>du", "<cmd>lua require'dap'.step_out()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dp", "<cmd>lua require'dap'.pause()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ds", "<cmd>lua require'dap'.continue()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dq", "<cmd>lua require'dap'.close()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>dU", "<cmd>lua require'dapui'.toggle({reset = true})<cr>", { noremap = true, silent = true })


return M
