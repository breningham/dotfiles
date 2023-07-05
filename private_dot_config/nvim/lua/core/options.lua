vim.g.loaded_netrw = 1     -- disable netrw for nvim-tree
vim.g.loaded_netrwPlugin = 1
vim.opt.compatible = false -- disable compatibility with old vi
vim.opt.showmatch = true   -- show matching brackets etc
vim.opt.ignorecase = true  -- case insensitive
vim.opt.mouse = "a"        -- enable mouse in all modes

-- tabs
vim.opt.expandtab = true  -- converts tabs to white spaces..
vim.opt.softtabstop = 4   -- see's multiple spaces as tabstops to <BS> does the right thing.
vim.opt.tabstop = 4       -- number of columns occupied by a tab.
vim.opt.shiftwidth = 4    -- width for autoindents.
vim.opt.autoindent = true -- indent a new line the same amount as the line above.

-- line wrapping
vim.opt.wrap = true

-- appearance
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes"
vim.opt.number = true -- line numbers
vim.cmd.colorscheme = "catppuccin-macchiato"

-- tab completion
vim.opt.wildmode = "longest,list"

-- search
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- clipboard
vim.opt.clipboard:append("unnamedplus")

-- perf
vim.opt.ttyfast = true

-- LSP
vim.cmd([[autocmd BufWritePre * lua vim.lsp.buf.format()]]) -- Format on write.

-- titles
vim.opt.title = false
