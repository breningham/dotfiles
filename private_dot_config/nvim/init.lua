-- Neovim 0.12 config. Native vim.pack, Catppuccin Macchiato, transparent to
-- match the kitty glass. Plugins live in lua/plugins.lua.
_G.nvim_start_ns = vim.uv.hrtime() -- read by the dashboard's startup line
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('plugins')
