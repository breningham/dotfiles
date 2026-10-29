local aug = function(name) return vim.api.nvim_create_augroup('bingham_' .. name, { clear = true }) end
local au = vim.api.nvim_create_autocmd

-- Flash the yanked region
au('TextYankPost', { group = aug('yank'), callback = function() vim.hl.on_yank({ higroup = 'IncSearch', timeout = 120 }) end })

-- Restore cursor position
au('BufReadPost', {
  group = aug('last_loc'),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- Resize splits when the OS window resizes
au('VimResized', { group = aug('resize'), command = 'tabdo wincmd =' })

-- Auto-create parent dirs on save
au('BufWritePre', {
  group = aug('mkdir'),
  callback = function(ev)
    if ev.match:match('^%w%w+:[\\/][\\/]') then return end
    vim.fn.mkdir(vim.fn.fnamemodify(ev.match, ':p:h'), 'p')
  end,
})

-- q closes helper windows
au('FileType', {
  group = aug('close_q'),
  pattern = { 'help', 'qf', 'man', 'checkhealth', 'notify', 'lspinfo', 'query', 'git', 'gitsigns-blame' },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = ev.buf, silent = true })
  end,
})

-- Wrap + spell in prose
au('FileType', {
  group = aug('prose'),
  pattern = { 'markdown', 'gitcommit', 'text' },
  callback = function() vim.wo.wrap = true; vim.wo.spell = true end,
})

-- Treesitter highlight + indent for any buffer that has a parser
au('FileType', {
  group = aug('treesitter'),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(ev.buf, lang)
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- LSP: keymaps, inlay hints, document highlight
au('LspAttach', {
  group = aug('lsp'),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end
    local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc }) end
    local ok, S = pcall(require, 'snacks')
    if ok then
      map('n', 'gd', function() S.picker.lsp_definitions() end, 'Goto definition')
      map('n', 'gr', function() S.picker.lsp_references() end, 'References')
      map('n', 'gI', function() S.picker.lsp_implementations() end, 'Implementations')
      map('n', 'gy', function() S.picker.lsp_type_definitions() end, 'Type definition')
      map('n', '<leader>ss', function() S.picker.lsp_symbols() end, 'Document symbols')
      map('n', '<leader>sS', function() S.picker.lsp_workspace_symbols() end, 'Workspace symbols')
    end
    map('n', 'gD', vim.lsp.buf.declaration, 'Declaration')
    map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('n', '<leader>cr', vim.lsp.buf.rename, 'Rename')
    map('i', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')
    if client:supports_method('textDocument/inlayHint') then vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf }) end
    if client:supports_method('textDocument/documentHighlight') then
      local g = aug('lsp_hl_' .. ev.buf)
      au({ 'CursorHold', 'CursorHoldI' }, { group = g, buffer = ev.buf, callback = vim.lsp.buf.document_highlight })
      au({ 'CursorMoved', 'CursorMovedI' }, { group = g, buffer = ev.buf, callback = vim.lsp.buf.clear_references })
    end
  end,
})

-- Reload buffers Claude edits behind our back (non-IDE mode): autoread + poll
vim.o.autoread = true
au({ 'FocusGained', 'BufEnter', 'CursorHold', 'TermLeave' }, { group = aug('checktime'), callback = function()
  if vim.fn.getcmdwintype() == '' and vim.fn.mode() ~= 'c' then vim.cmd('checktime') end
end })
local ct = vim.uv.new_timer()
ct:start(2000, 2000, vim.schedule_wrap(function()
  if vim.fn.getcmdwintype() == '' and vim.fn.mode() ~= 'c' then pcall(vim.cmd, 'silent! checktime') end
end))
au('FileChangedShellPost', { group = aug('reloaded'), callback = function(ev)
  vim.notify('Reloaded ' .. vim.fn.fnamemodify(ev.file, ':~:.'), vim.log.levels.INFO, { title = 'File changed on disk' })
end })
