local map = vim.keymap.set

-- Sanity
map('n', '<Esc>', '<cmd>nohlsearch<cr><Esc>', { desc = 'Clear search highlight' })
map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><Esc>', { desc = 'Save file' })
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'Write' })
map('x', 'p', '"_dP', { desc = 'Paste without yanking' })
map('n', 'U', '<C-r>', { desc = 'Redo' })

-- Better movement
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Windows
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })
map('n', '<leader>-', '<C-w>s', { desc = 'Split below' })
map('n', '<leader>|', '<C-w>v', { desc = 'Split right' })
map('n', '<leader>wd', '<C-w>c', { desc = 'Close window' })
map('n', '<C-Up>', '<cmd>resize +2<cr>')
map('n', '<C-Down>', '<cmd>resize -2<cr>')
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>')
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>')

-- Buffers
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
map('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Alternate buffer' })

-- Move lines
map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move line down' })
map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move line up' })
map('x', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move down' })
map('x', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move up' })
map('x', '<', '<gv')
map('x', '>', '>gv')

-- Diagnostics
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Next diagnostic' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'Prev diagnostic' })
map('n', '<leader>ul', function()
  local cfg = vim.diagnostic.config()
  vim.diagnostic.config({ virtual_lines = not cfg.virtual_lines, virtual_text = cfg.virtual_lines and { spacing = 2, prefix = '●' } or false })
end, { desc = 'Toggle diagnostic virtual lines' })

-- Toggles
map('n', '<leader>uw', function() vim.o.wrap = not vim.o.wrap end, { desc = 'Toggle wrap' })
map('n', '<leader>us', function() vim.o.spell = not vim.o.spell end, { desc = 'Toggle spell' })
map('n', '<leader>un', function() vim.o.relativenumber = not vim.o.relativenumber end, { desc = 'Toggle relative numbers' })
map('n', '<leader>uh', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = 'Toggle inlay hints' })

-- Terminal
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Misc
map('n', '<leader>L', '<cmd>Lazy<cr>', { desc = 'Plugins (vim.pack)' })
map('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })
map('n', '<leader>ch', '<cmd>checkhealth<cr>', { desc = 'Checkhealth' })
