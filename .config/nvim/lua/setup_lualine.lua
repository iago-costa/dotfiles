local custom_theme = require 'lualine.themes.iceberg_dark'

-- Change the background of lualine_c section for normal mode
custom_theme.normal.c.fg = 'White'
custom_theme.normal.b.fg = 'White'
custom_theme.normal.a.fg = 'White'

custom_theme.insert.a.fg = 'White'
custom_theme.insert.b.fg = 'White'

custom_theme.visual.a.fg = 'White'
custom_theme.visual.b.fg = 'White'

custom_theme.replace.a.fg = 'White'
custom_theme.replace.b.fg = 'White'

require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = custom_theme,
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
}
