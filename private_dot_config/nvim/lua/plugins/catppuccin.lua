vim.cmd.colorscheme = "catppuccin-macchiato"

require("catppuccin").setup({
    flavour = "macchiato",
    term_colors = true,
    show_end_of_buffer = false,
    styles = {
        comments = { "italic" },
    },
    integrations = {
        cmp = true,
        nvimtree = true,
        telescope = true,
        coc_nvim = true,
        dashboard = true,
        native_lsp = {
            enabled = true,
            virtual_text = {
                errors = { "italic" },
                hints = { "italic" },
                warnings = { "italic" },
                information = { "italic" },
            },
            underlines = {
                errors = { "underline" },
                hints = { "underline" },
                warnings = { "underline" },
                information = { "underline" },
            },
            inlay_hints = {
                background = true,
            },
        },
        lsp_saga = false,
        treesitter = true,
        gitsigns = true,
        barbar = true,
    },
})
