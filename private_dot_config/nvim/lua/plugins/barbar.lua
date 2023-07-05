local bb_status, barbar = pcall(require, "barbar")
if not bb_status then
    return
end

vim.g.barbar_auto_setup = false

barbar.setup({
    sidebar_filetypes = {
        NvimTree = true,
    },
    no_name_title = nil,
    icons = {
        gitsigns = {
            enabled = true,
        },
    },
})
