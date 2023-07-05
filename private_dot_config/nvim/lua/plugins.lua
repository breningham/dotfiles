local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

-- Auto update and reload plugins when this file is updated
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- import packer safely
local status, packer = pcall(require, "packer")
if not status then
    return
end

return packer.startup(function(use)
    use("wbthomason/packer.nvim")

    -- utilities that many plugins use
    use("nvim-lua/plenary.nvim")

    -- gitsigns
    use("lewis6991/gitsigns.nvim")

    -- nvim-tree
    use("nvim-tree/nvim-web-devicons")
    use({
        "nvim-tree/nvim-tree.lua",
        config = function()
            require("plugins/nvim-tree")
        end,
    })
    -- nvim treesitter (syntax highlighting)
    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
            ts_update()
        end,
        config = function()
            require("plugins/nvim-treesitter")
        end,
    })

    use({
        "freddiehaddad/feline.nvim",
        config = function()
            require("plugins/feline")
        end,
    })

    use({
        "romgrk/barbar.nvim",
        config = function()
            require("plugins.barbar")
        end,
    })

    -- theming
    use({
        "catppuccin/nvim",
        as = "catppuccin",
        config = function()
            require("plugins/catppuccin")
        end,
    })
    use({
        "nvimdev/dashboard-nvim",
        config = function()
            require("plugins/dashboard")
        end,
    })

    -- telescope
    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.x",
        config = function()
            require("plugins/telescope")
        end,
    })

    -- lsp
    use({
        "neovim/nvim-lspconfig",
        config = function()
            require("plugins/nvim-lspconfig")
        end,
    }) -- LSP Configuration helpers

    use({
        "glepnir/lspsaga.nvim",
        branch = "main",
        event = "LspAttach",
        config = function()
            require("lspsaga").setup({})
        end,
    }) -- Improved LSP Interface
    use("dcampos/nvim-snippy")
    use("dcampos/cmp-snippy")

    use("hrsh7th/cmp-nvim-lsp")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")
    use("hrsh7th/cmp-cmdline")
    use({
        "hrsh7th/nvim-cmp",
        config = function()
            require("plugins/nvim-cmp")
        end,
        requires = {
            { "dcampos/nvim-snippy" },
            { "dcampos/cmp-snippy" },
            { "onsails/lspkind.nvim" },
        },
    }) -- Autocomplete

    use({
        "mhartington/formatter.nvim",
        config = function()
            require("plugins/formatter")
        end,
    }) -- Formatter integration

    -- git
    use("ThePrimeagen/git-worktree.nvim")
    if packer_bootstrap then
        require("packer").sync()
    end
end)
