require('packer').startup(function()
    -- Define your plugins here
    -- Example: use 'username/repo'
    use('nvim-tree/nvim-web-devicons') -- optional icons for nvim-tree
    use('andymass/vim-matchup')        -- highlight matching words under cursor
    use('github/copilot.vim')          -- copilot

    use({
        'VonHeikemen/lsp-zero.nvim', -- LSP support
        branch = 'v3.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig', {
            } }, -- config LSP servers
            {
                'williamboman/mason.nvim',
                opts = {

                }
            }, -- install LSP servers
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' }, -- config autocomplete
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'saadparwaiz1/cmp_luasnip' },
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },

            -- Rust
            { 'simrat39/rust-tools.nvim' },

            -- Debugging
            { 'nvim-lua/plenary.nvim' },
            {
                'mfussenegger/nvim-dap',
                requires = {
                    'rcarriga/nvim-dap-ui',
                    'mfussenegger/nvim-dap-python',
                    'theHamsta/nvim-dap-virtual-text',
                    'nvim-telescope/telescope-dap.nvim',
                    'folke/which-key.nvim',
                },
                init = function()
                    require("core.utils").load_mappings("dap")
                end
            },
            {
                "leoluz/nvim-dap-go",
                ft = "go",
                dependencies = { "mfussenegger/nvim-dap" },
                config = function(_, opts)
                    require("dap-go").setup(opts)
                end,
            },

            use { --  flutter tools
                'akinsho/flutter-tools.nvim',
                requires = {
                    'nvim-lua/plenary.nvim',
                    'stevearc/dressing.nvim', -- optional for vim.ui.select
                },
            },

            use { 'jose-elias-alvarez/null-ls.nvim', -- null-ls for formatting and linting support
                ft = "go",
                opts = function()
                    return require("lsp_comfigs/null-ls")
                end,
            },
        }
    })

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
            vim.cmd('colorscheme github_dark_tritanopia')
        end
    })

    use({
        "folke/trouble.nvim", -- see list of diagnostics
        requires = { "nvim-tree/nvim-web-devicons", "folke/lsp-colors.nvim" },
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

    use { -- fold look like vscode
        'kevinhwang91/nvim-ufo',
        requires = 'kevinhwang91/promise-async'
    }

    use({
        "aaronhallaert/advanced-git-search.nvim", -- git history commits changes for files and more
        requires = {
            "nvim-telescope/telescope.nvim",
            -- to show diff splits and open commits in browser
            "tpope/vim-fugitive",
            -- to open commits in browser with fugitive
            "tpope/vim-rhubarb",
            -- optional: to replace the diff from fugitive with diffview.nvim
            -- (fugitive is still needed to open in browser)
            "sindrets/diffview.nvim",
        },
    })

    use { -- nvim cmdline completion
        'gelguy/wilder.nvim',
        requires = { 'romgrk/fzy-lua-native' },
    }

    -- use('Olical/conjure')                  -- clojure REPL

    use('HiPhish/rainbow-delimiters.nvim') -- rainbow delimiters

    use('saecki/crates.nvim')              -- crates.io integration for rust

    use('j-morano/buffer_manager.nvim')    -- buffer manager

    use("907th/vim-auto-save")             -- auto save
    use({                                  --  auto save session nvim
        'rmagatti/auto-session',
        config = function()
            require("auto-session").setup {
                log_level = "error",
                auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
            }
        end
    })

    use({ -- custom status line
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    })

    use({
        'nvim-pack/nvim-spectre' -- search and replace
    })

    -- use({ --  replace between multiple files
    --     'dyng/ctrlsf.vim',
    -- })
end)
