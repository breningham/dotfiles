local lspConfig = require("lspconfig")

lspConfig.tsserver.setup({})

lspConfig.lua_ls.setup({
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
        },
    },
})

lspConfig.cssmodules_ls.setup({})
lspConfig.cssls.setup({})

lspConfig.eslint.setup({
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
        })
    end,
})

local htmlCapabilities = vim.lsp.protocol.make_client_capabilities()
htmlCapabilities.textDocument.completion.completionItem.snippetSupport = true

lspConfig.html.setup({
    capabilties = htmlCapabilities,
})
