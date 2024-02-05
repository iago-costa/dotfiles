local M = {}

M.dap = {
    plugin = true,
    n = {
        ["<leader>db"] = {
            "<cmd> DapToggleBreakpoint<CR>",
            "Add/Remove breakpoint",
        },
        ["<leader>dus"] = {
            function()
                local widgets = require("dap.ui.widgets");
                local sidebar = widgets.sidebar(widgets.scopes);
                sidebar.open();
            end,
            "Open debug sidebar",
        },
    },
}

M.dap_go = {
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
        },
    },
}

return M
