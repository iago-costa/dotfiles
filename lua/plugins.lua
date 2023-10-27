require('packer').startup(function()
    -- Define your plugins here
    -- Example: use 'username/repo'
    use('nvim-tree/nvim-web-devicons') -- optional icons for nvim-tree
    use('kyazdani42/nvim-tree.lua')    -- file explorer
    use('andymass/vim-matchup')        -- highlight matching words under cursor
    use('github/copilot.vim')          -- copilot

    use({
        'VonHeikemen/lsp-zero.nvim', -- LSP support
        branch = 'v3.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },   -- config LSP servers
            { 'williamboman/mason.nvim' }, -- install LSP servers
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' }, -- config autocomplete
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },

            -- Rust
            { 'simrat39/rust-tools.nvim' },

            -- Debugging
            { 'nvim-lua/plenary.nvim' },
            { 'mfussenegger/nvim-dap' },

            use { --  flutter tools
                'akinsho/flutter-tools.nvim',
                requires = {
                    'nvim-lua/plenary.nvim',
                    'stevearc/dressing.nvim', -- optional for vim.ui.select
                },
            },

            use('jose-elias-alvarez/null-ls.nvim'), -- null-ls for formatting and linting support to javascript
            use('MunifTanjim/eslint.nvim')          -- eslint for javascript
        }
    })

    use { "akinsho/toggleterm.nvim", tag = '*', config = function() -- terminal in a floating window
        require("toggleterm").setup()
    end }

    -- install live grep and telescope
    use({
        'nvim-telescope/telescope.nvim',
        tag = '0.1.3',
        requires = {
            { 'nvim-lua/plenary.nvim' },
            { 'nvim-telescope/telescope-fzy-native.nvim' },
            { 'duane9/nvim-rg' }
        }
    })

    use({
        'jemag/telescope-diff.nvim', -- diff telescope
        requires = {
            { 'nvim-telescope/telescope.nvim' },
            { 'nvim-lua/plenary.nvim' },
        }
    })

    use('tpope/vim-commentary') -- comment out lines

    -- Main colorscheme and theme
    use({
        'projekt0n/github-nvim-theme',
        config = function()
            require('github-theme').setup({
            })
            vim.cmd('colorscheme github_dark_colorblind')
        end
    })

    use({
        "folke/trouble.nvim", -- see list of diagnostics
        config = function()
            require("trouble").setup {
                icons = false,
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    })
    use({
        'nvim-treesitter/nvim-treesitter', -- treesitter for syntax highlighting
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
    })
    use("nvim-treesitter/playground")               -- playground for treesitter
    use("nvim-treesitter/nvim-treesitter-context"); -- show context of code
    use("theprimeagen/harpoon")                     -- box to store files to jump to
    use("theprimeagen/refactoring.nvim")            -- refactoring tool
    use("mbbill/undotree")                          -- undo tree visualizer and navigation with timeline
    use("907th/vim-auto-save")                      -- auto save
    use({
        "kdheepak/lazygit.nvim",                    -- git wrapper for neovim
        -- optional for floating window border decoration
        requires = {
            "nvim-lua/plenary.nvim",
        },
    })

    use {
        'lewis6991/gitsigns.nvim', -- git signs to blame line, highlight diff and other cool stuff for git
        requires = { 'nvim-lua/plenary.nvim' },
    }

    use { --  multiple cursors
        'mg979/vim-visual-multi',
        branch = 'master'
    }

    use { --  replace between multiple files
        'dyng/ctrlsf.vim',
    }

    use { --  command-completion to cli nvim
        'smolck/command-completion.nvim',
    }

    use { -- fold look like vscode
        'kevinhwang91/nvim-ufo',
        requires = 'kevinhwang91/promise-async'
    }

    use('romgrk/barbar.nvim')              -- multitabs

    use('tpope/vim-fugitive')              -- git wrapper to git history, blame, etc

    use('Olical/conjure')                  -- clojure REPL

    use('HiPhish/rainbow-delimiters.nvim') -- rainbow delimiters
end)
