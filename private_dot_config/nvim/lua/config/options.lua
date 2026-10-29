local o = vim.o

-- UI
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.termguicolors = true
o.winborder = 'rounded'
o.laststatus = 3 -- one global statusline
o.cmdheight = 1
o.showmode = false
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.linebreak = true
o.list = true
o.listchars = 'tab:  ,trail:·,nbsp:␣,extends:›,precedes:‹'
o.fillchars = 'eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸,diff:╱'
o.pumheight = 12
o.pumblend = 0
o.winblend = 0
o.conceallevel = 2
o.splitbelow = true
o.splitright = true
o.splitkeep = 'screen'
o.mouse = 'a'
o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250'

-- Editing
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.shiftround = true
o.smartindent = true
o.breakindent = true
o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'
o.confirm = true
o.virtualedit = 'block'
o.formatoptions = 'jcroqlnt'
o.completeopt = 'menu,menuone,noselect,fuzzy'
o.spelllang = 'en_gb'

-- Files
o.undofile = true
o.undolevels = 10000
o.swapfile = false
o.backup = false
o.updatetime = 200
o.timeoutlen = 400
o.autowrite = true
o.clipboard = 'unnamedplus'

-- Folds via treesitter, open by default
o.foldmethod = 'expr'
o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldlevel = 99
o.foldlevelstart = 99
o.foldtext = ''

-- Search tools
if vim.fn.executable('rg') == 1 then
  o.grepprg = 'rg --vimgrep --smart-case --hidden --glob !.git'
  o.grepformat = '%f:%l:%c:%m'
end

-- Disable builtin plugins we replace
for _, p in ipairs({ 'netrwPlugin', 'tutor', 'tohtml', 'gzip', 'tarPlugin', 'zipPlugin' }) do
  vim.g['loaded_' .. p] = 1
end

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = '●', source = 'if_many' },
  virtual_lines = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  },
})
