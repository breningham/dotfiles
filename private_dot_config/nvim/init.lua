vim.g["node_host_prog"] = vim.call("system", 'volta which neovim-node-host | tr -d "\n"')

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
