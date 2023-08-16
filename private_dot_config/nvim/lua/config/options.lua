-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
--
-- fix nodejs with volta
local g = vim.g

g["node_host_prog"] = vim.call("system", 'volta which neovim-node-host | tr -d "\n"')
