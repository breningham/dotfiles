local ctp_status, ctp = pcall(require, "catppuccin.groups.integrations.feline")
if not ctp_status then
    return
end

local feline_status, feline = pcall(require, "feline")
if not feline_status then
    return
end

ctp.setup({})

feline.setup({
    components = ctp.get(),
})

feline.statuscolumn.setup()
