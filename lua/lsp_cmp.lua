local cmp = require('cmp')

cmp.setup({
    sources = {
        {name = 'nvim_lsp'},
        {name = 'luasnip'},
        {name = 'rust-tools'},
        -- {name = 'pyright'},
    },
    mapping = {
        ['<Enter>'] = cmp.mapping.confirm({select = false}),
        ['<Esc>'] = cmp.mapping.abort(),
        ['<Up>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
        ['<Down>'] = cmp.mapping.select_next_item({behavior = 'select'}),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-p>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item({behavior = 'insert'})
            else
                cmp.complete()
            end
        end),
        ['<C-n>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_next_item({behavior = 'insert'})
            else
                cmp.complete()
            end
        end),
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
})

-- init doc key
-- Enter = confirm completion
-- Esc = abort completion
-- Up = select prev item
-- Down = select next item
-- C-d = scroll documentation up
-- C-f = scroll documentation down
-- C-p = select prev item
-- end doc key
