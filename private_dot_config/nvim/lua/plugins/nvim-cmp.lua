-- import nvim-cmp plugin safely
local cmp_status, cmp = pcall(require, "cmp")
if not cmp_status then
    return
end

-- import lspkind plugin safely
local lspkind_status, lspkind = pcall(require, "lspkind")
if not lspkind_status then
    return
end

vim.opt.completeopt = "menu,menuone,noselect"

cmp.setup({
    snippet = {
        expand = function(args)
            require("snippy").expand_snippet(args.body)
        end,
    },
    window = {},
    mapping = {
        ["<C-.>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    },
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "snippy" },
        { name = "buffer" },
        { name = "path" },
    }),
    formatting = {
        format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
        }),
    },
})

-- cmdline setup
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        {
            name = "cmdline",
            option = {
                ignore_cmds = { "Man", "!" },
            },
        },
    }),
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

lspconfig.tsserver.setup({
    capabilities = capabilities,
})

lspconfig.lua_ls.setup({
    capabilities = capabilities,
})
