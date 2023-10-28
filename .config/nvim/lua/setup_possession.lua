require('possession').setup {
    -- session dir inside nvim folder
    -- session_dir = vim.fn.expand('~/.config/nvim') .. '/sessions/',
    --
    silent = false,
    load_silent = true,
    debug = false,
    logfile = false,
    prompt_no_cr = false,
    autosave = {
        current = true,   -- or fun(name): boolean
        tmp = true,       -- or fun(): boolean
        tmp_name = 'tmp', -- or fun(): string
        on_load = true,
        on_quit = true,
    },
    commands = {
        save = 'SSave',
        load = 'SLoad',
        rename = 'SRename',
        close = 'SClose',
        delete = 'SDelete',
        show = 'SShow',
        list = 'SList',
        migrate = 'SMigrate',
    },
    -- hooks = {
    --     before_save = function(name) return {} end,
    --     after_save = function(name, user_data, aborted) end,
    --     before_load = function(name, user_data) return user_data end,
    --     after_load = function(name, user_data) end,
    -- },
    -- plugins = {
    --     close_windows = {
    --         hooks = { 'before_save', 'before_load' },
    --         preserve_layout = true, -- or fun(win): boolean
    --         match = {
    --             floating = true,
    --             buftype = {},
    --             filetype = {},
    --             custom = false, -- or fun(win): boolean
    --         },
    --     },
    --     delete_hidden_buffers = {
    --         hooks = {
    --             'before_load',
    --             vim.o.sessionoptions:match('buffer') and 'before_save',
    --         },
    --         force = false, -- or fun(buf): boolean
    --     },
    --     nvim_tree = true,
    --     neo_tree = true,
    --     symbols_outline = true,
    --     tabby = true,
    --     dap = true,
    --     dapui = true,
    --     delete_buffers = false,
    -- },
    telescope = {
        list = {
            default_action = 'load',
            mappings = {
                save = { n = '<c-x>', i = '<c-x>' },
                load = { n = '<c-v>', i = '<c-v>' },
                delete = { n = '<c-t>', i = '<c-t>' },
                rename = { n = '<c-r>', i = '<c-r>' },
            },
        },
    },
}


require('telescope').load_extension('possession')

-- To display the current session name in statusline/winbar/etc. you can define the following function:
local function session_name()
    return require('possession.session').session_name or ''
end

-- Key to :Telescope possession list
vim.api.nvim_set_keymap('n', '<leader>pl', ':Telescope possession list<CR>', { noremap = true, silent = true })

-- init doc key
-- {'n'} <leader>pl = Telescope possession list
-- end doc key
