-- Plugins via Neovim 0.12's native vim.pack. Run :PackUpdate to update.
local gh = function(repo) return 'https://github.com/' .. repo end

vim.pack.add({
  -- UI
  gh('catppuccin/nvim'),
  gh('nvim-lualine/lualine.nvim'),
  gh('folke/snacks.nvim'),
  gh('folke/which-key.nvim'),
  gh('nvim-mini/mini.nvim'),
  gh('j-hui/fidget.nvim'),
  gh('MeanderingProgrammer/render-markdown.nvim'),
  -- Editing
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  gh('folke/flash.nvim'),
  gh('stevearc/conform.nvim'),
  gh('folke/todo-comments.nvim'),
  gh('nvim-lua/plenary.nvim'),
  -- LSP / completion
  gh('neovim/nvim-lspconfig'),
  gh('mason-org/mason.nvim'),
  gh('mason-org/mason-lspconfig.nvim'),
  gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  { src = gh('saghen/blink.cmp'), version = vim.version.range('1.*') },
  gh('folke/lazydev.nvim'),
  gh('folke/trouble.nvim'),
  -- Git
  gh('lewis6991/gitsigns.nvim'),
  gh('sindrets/diffview.nvim'),
  -- Claude Code
  gh('coder/claudecode.nvim'),
}, { confirm = false })

vim.api.nvim_create_user_command('PackUpdate', function() vim.pack.update() end, { desc = 'Update all plugins' })
vim.api.nvim_create_user_command('Lazy', function() vim.pack.update() end, { desc = 'Update all plugins (alias)' })

local is_review = vim.g.claude_review == 1

-- ── Colours ─────────────────────────────────────────────────────────────────
require('catppuccin').setup({
  flavour = 'macchiato',
  transparent_background = true, -- kitty supplies the glass
  float = { transparent = true, solid = false },
  show_end_of_buffer = false,
  term_colors = true,
  dim_inactive = { enabled = false },
  styles = {
    comments = { 'italic' },
    conditionals = { 'italic' },
    keywords = { 'italic' },
    functions = { 'bold' },
  },
  integrations = {
    blink_cmp = { style = 'bordered' },
    diffview = true,
    fidget = true,
    flash = true,
    gitsigns = true,
    lsp_trouble = true,
    markdown = true,
    mason = true,
    mini = { enabled = true, indentscope_color = 'lavender' },
    native_lsp = {
      enabled = true,
      underlines = { errors = { 'undercurl' }, hints = { 'undercurl' }, warnings = { 'undercurl' }, information = { 'undercurl' } },
    },
    render_markdown = true,
    snacks = { enabled = true, indent_scope_color = 'lavender' },
    treesitter = true,
    which_key = true,
  },
  custom_highlights = function(c)
    return {
      CursorLine = { bg = c.surface0, blend = 40 },
      WinSeparator = { fg = c.surface1 },
      FloatBorder = { fg = c.lavender },
      NormalFloat = { bg = 'NONE' },
      Pmenu = { bg = c.mantle },
      PmenuSel = { bg = c.surface1, fg = c.text },
      LspInlayHint = { fg = c.overlay0, style = { 'italic' } },
      SnacksIndent = { fg = c.surface0 },
      SnacksIndentScope = { fg = c.lavender },
      SnacksPickerDir = { fg = c.overlay1 },
      ClaudeCodeInlineDiffAdd = { bg = '#2a3d3a' },
      ClaudeCodeInlineDiffDelete = { bg = '#4a2f3a', style = { 'strikethrough' } },
      DiffviewDiffAddAsDelete = { bg = '#4a2f3a' },
      DiffAdd = { bg = '#2a3d3a' },
      DiffDelete = { bg = '#4a2f3a' },
      DiffChange = { bg = '#2f3550' },
      DiffText = { bg = '#45507a', style = { 'bold' } },
    }
  end,
})
vim.cmd.colorscheme('catppuccin')

-- ── mini: pairs, surround, textobjects, icons ───────────────────────────────
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.ai').setup({ n_lines = 500 })

-- ── Snacks ──────────────────────────────────────────────────────────────────
local header = table.concat({
  '███╗   ██╗██╗   ██╗██╗███╗   ███╗',
  '████╗  ██║██║   ██║██║████╗ ████║',
  '██╔██╗ ██║██║   ██║██║██╔████╔██║',
  '██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║',
  '██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║',
  '╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝',
}, '\n')

require('snacks').setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = not is_review,
    preset = {
      header = header,
      keys = {
        { icon = '\u{f15b} ', key = 'f', desc = 'Find file', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = '\u{f067} ', key = 'n', desc = 'New file', action = ':ene | startinsert' },
        { icon = '\u{f002} ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = '\u{f017} ', key = 'r', desc = 'Recent', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = '✦ ', key = 'a', desc = 'Claude Code', action = ':ClaudeCode' },
        { icon = '\u{e728} ', key = 'd', desc = 'Diffview', action = ':DiffviewOpen' },
        { icon = '󰒲 ', key = 'u', desc = 'Update plugins', action = ':PackUpdate' },
        { icon = '\u{f011} ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { icon = '\u{f0c5} ', title = 'Recent files', section = 'recent_files', cwd = true, indent = 2, padding = 1 },
      -- Git status as plain text (a 'terminal' section leaves [Process exited 0]
      -- behind); hidden outside a repo and when the tree is clean.
      function()
        if not Snacks.git.get_root() then return end
        local r = vim.system({ 'git', 'status', '--short' }, { text = true }):wait()
        if r.code ~= 0 or r.stdout == '' then return end
        local hl = { M = 'DiagnosticWarn', A = 'DiagnosticOk', D = 'DiagnosticError', R = 'DiagnosticInfo', ['?'] = 'Comment' }
        local items = { { icon = '\u{e702} ', title = 'Git status', padding = 1 } }
        local lines = vim.split(r.stdout:gsub('%s+$', ''), '\n') -- keep the leading status column
        for n, line in ipairs(lines) do
          if n > 8 then
            items[#items + 1] = { text = { { ('  … %d more'):format(#lines - 8), hl = 'Comment' } }, indent = 2 }
            break
          end
          local code = line:sub(1, 2):gsub(' ', '')
          items[#items + 1] = { text = { { line:sub(1, 2) .. ' ', hl = hl[code:sub(1, 1)] or 'Comment' }, { line:sub(4), hl = 'Normal' } }, indent = 2 }
        end
        items[#items].padding = 1
        return items
      end,
      -- snacks' built-in 'startup' section needs lazy.nvim's stats; vim.pack has none.
      function()
        -- Sections re-run on every redraw; freeze the time at first render.
        _G.nvim_startup_ms = _G.nvim_startup_ms or (vim.uv.hrtime() - _G.nvim_start_ns) / 1e6
        local ms = _G.nvim_startup_ms
        local n = #vim.pack.get()
        return { align = 'center', text = { { '⚡ Neovim loaded ', hl = 'footer' }, { n .. ' plugins', hl = 'special' }, { (' in %.1fms'):format(ms), hl = 'footer' } } }
      end,
    },
  },
  dim = { enabled = true },
  explorer = { enabled = true, replace_netrw = true },
  image = { enabled = true }, -- inline images via the kitty graphics protocol
  indent = { enabled = true, animate = { enabled = true }, scope = { enabled = true } },
  input = { enabled = true },
  lazygit = { enabled = true },
  notifier = { enabled = true, timeout = 3000, style = 'compact', top_down = false },
  picker = {
    enabled = true,
    layout = { preset = 'ivy' },
    sources = { explorer = { layout = { layout = { position = 'left', width = 32 } } } },
  },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true, folds = { open = true, git_hl = true } },
  terminal = { enabled = true },
  toggle = { enabled = true },
  words = { enabled = true },
  zen = { enabled = true },
  styles = { notification = { wo = { wrap = true } } },
})

local S = Snacks
local map = vim.keymap.set
-- Files / search
map('n', '<leader><space>', function() S.picker.smart() end, { desc = 'Smart find' })
map('n', '<leader>ff', function() S.picker.files() end, { desc = 'Files' })
map('n', '<leader>fg', function() S.picker.git_files() end, { desc = 'Git files' })
map('n', '<leader>fr', function() S.picker.recent() end, { desc = 'Recent' })
map('n', '<leader>fb', function() S.picker.buffers() end, { desc = 'Buffers' })
map('n', '<leader>fc', function() S.picker.files({ cwd = vim.fn.stdpath('config') }) end, { desc = 'Config files' })
map('n', '<leader>fp', function() S.picker.projects() end, { desc = 'Projects' })
map('n', '<leader>/', function() S.picker.grep() end, { desc = 'Grep' })
map('n', '<leader>sg', function() S.picker.grep() end, { desc = 'Grep' })
map({ 'n', 'x' }, '<leader>sw', function() S.picker.grep_word() end, { desc = 'Grep word' })
map('n', '<leader>sb', function() S.picker.lines() end, { desc = 'Buffer lines' })
map('n', '<leader>sd', function() S.picker.diagnostics() end, { desc = 'Diagnostics' })
map('n', '<leader>sD', function() S.picker.diagnostics_buffer() end, { desc = 'Buffer diagnostics' })
map('n', '<leader>sh', function() S.picker.help() end, { desc = 'Help' })
map('n', '<leader>sk', function() S.picker.keymaps() end, { desc = 'Keymaps' })
map('n', '<leader>sm', function() S.picker.marks() end, { desc = 'Marks' })
map('n', '<leader>sr', function() S.picker.resume() end, { desc = 'Resume picker' })
map('n', '<leader>su', function() S.picker.undo() end, { desc = 'Undo tree' })
map('n', '<leader>sc', function() S.picker.commands() end, { desc = 'Commands' })
map('n', '<leader>s:', function() S.picker.command_history() end, { desc = 'Command history' })
map('n', '<leader>st', function() S.picker.todo_comments() end, { desc = 'Todos' })
map('n', '<leader>uC', function() S.picker.colorschemes() end, { desc = 'Colorschemes' })
map('n', '<leader>e', function() S.explorer() end, { desc = 'Explorer' })
-- Git
map('n', '<leader>gg', function() S.lazygit() end, { desc = 'Lazygit' })
map('n', '<leader>gl', function() S.picker.git_log() end, { desc = 'Git log' })
map('n', '<leader>gL', function() S.picker.git_log_line() end, { desc = 'Git log (line)' })
map('n', '<leader>gs', function() S.picker.git_status() end, { desc = 'Git status' })
map('n', '<leader>gS', function() S.picker.git_stash() end, { desc = 'Git stash' })
map('n', '<leader>gb', function() S.picker.git_branches() end, { desc = 'Git branches' })
map('n', '<leader>gB', function() S.gitbrowse() end, { desc = 'Git browse' })
map('n', '<leader>gf', function() S.picker.git_log_file() end, { desc = 'Git file history' })
-- Misc
map('n', '<leader>n', function() S.notifier.show_history() end, { desc = 'Notification history' })
map('n', '<leader>un', function() S.notifier.hide() end, { desc = 'Dismiss notifications' })
map('n', '<leader>z', function() S.zen() end, { desc = 'Zen mode' })
map('n', '<leader>Z', function() S.zen.zoom() end, { desc = 'Zoom' })
map('n', '<leader>.', function() S.scratch() end, { desc = 'Scratch buffer' })
map('n', '<leader>bd', function() S.bufdelete() end, { desc = 'Delete buffer' })
map('n', '<leader>bo', function() S.bufdelete.other() end, { desc = 'Delete other buffers' })
map('n', '<leader>cR', function() S.rename.rename_file() end, { desc = 'Rename file' })
map({ 'n', 't' }, '<C-/>', function() S.terminal() end, { desc = 'Terminal' })
map({ 'n', 't' }, '<C-_>', function() S.terminal() end, { desc = 'Terminal' })
map({ 'n', 't' }, ']]', function() S.words.jump(vim.v.count1) end, { desc = 'Next reference' })
map({ 'n', 't' }, '[[', function() S.words.jump(-vim.v.count1) end, { desc = 'Prev reference' })
S.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
S.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
S.toggle.option('relativenumber', { name = 'Relative number' }):map('<leader>un')
S.toggle.diagnostics():map('<leader>ud')
S.toggle.line_number():map('<leader>uN')
S.toggle.treesitter():map('<leader>uT')
S.toggle.inlay_hints():map('<leader>uh')
S.toggle.indent():map('<leader>ug')
S.toggle.dim():map('<leader>uD')

-- ── which-key ───────────────────────────────────────────────────────────────
require('which-key').setup({
  preset = 'helix',
  delay = 300,
  spec = {
    { '<leader>a', group = 'claude', icon = '✦' },
    { '<leader>b', group = 'buffer' },
    { '<leader>c', group = 'code' },
    { '<leader>f', group = 'find' },
    { '<leader>g', group = 'git' },
    { '<leader>q', group = 'quit' },
    { '<leader>s', group = 'search' },
    { '<leader>u', group = 'ui' },
    { '<leader>w', group = 'window' },
    { '<leader>x', group = 'diagnostics' },
    { 'g', group = 'goto' },
    { 'z', group = 'fold' },
    { '[', group = 'prev' },
    { ']', group = 'next' },
  },
})

-- ── Treesitter (main branch) ────────────────────────────────────────────────
local ts_langs = {
  'bash', 'c', 'cpp', 'css', 'diff', 'dockerfile', 'fish', 'git_config', 'git_rebase', 'gitcommit', 'gitignore',
  'go', 'gomod', 'gosum', 'html', 'hyprlang', 'ini', 'javascript', 'jsdoc', 'json', 'json5', 'jsonc', 'just',
  'kdl', 'lua', 'luadoc', 'luap', 'make', 'markdown', 'markdown_inline', 'nix', 'python', 'query', 'regex',
  'rust', 'scss', 'sql', 'ssh_config', 'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'xml', 'yaml', 'zig',
}
require('nvim-treesitter').setup({ install_dir = vim.fn.stdpath('data') .. '/site' })
vim.api.nvim_create_user_command('TSInstallAll', function() require('nvim-treesitter').install(ts_langs) end, {})

-- ── Flash ───────────────────────────────────────────────────────────────────
require('flash').setup({ label = { uppercase = false, rainbow = { enabled = true } } })
map({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash' })
map({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash treesitter' })
map('o', 'r', function() require('flash').remote() end, { desc = 'Remote flash' })
map({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Treesitter search' })
map('c', '<C-s>', function() require('flash').toggle() end, { desc = 'Toggle flash search' })

-- ── Todo comments / Trouble ─────────────────────────────────────────────────
require('todo-comments').setup()
map('n', ']t', function() require('todo-comments').jump_next() end, { desc = 'Next todo' })
map('n', '[t', function() require('todo-comments').jump_prev() end, { desc = 'Prev todo' })
require('trouble').setup({ focus = true })
map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
map('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer diagnostics' })
map('n', '<leader>xs', '<cmd>Trouble symbols toggle<cr>', { desc = 'Symbols' })
map('n', '<leader>xl', '<cmd>Trouble lsp toggle<cr>', { desc = 'LSP refs/defs' })
map('n', '<leader>xq', '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix' })

-- ── Git ─────────────────────────────────────────────────────────────────────
require('gitsigns').setup({
  signs = { add = { text = '▎' }, change = { text = '▎' }, delete = { text = '▁' }, topdelete = { text = '▔' }, changedelete = { text = '▎' }, untracked = { text = '▎' } },
  signs_staged = { add = { text = '▎' }, change = { text = '▎' }, delete = { text = '▁' }, topdelete = { text = '▔' }, changedelete = { text = '▎' } },
  current_line_blame = true,
  current_line_blame_opts = { delay = 500, virt_text_pos = 'eol' },
  current_line_blame_formatter = '  <author>, <author_time:%R> · <summary>',
  watch_gitdir = { follow_files = true },
  on_attach = function(buf)
    local gs = require('gitsigns')
    local bmap = function(mode, l, r, desc) map(mode, l, r, { buffer = buf, desc = desc }) end
    bmap('n', ']h', function() if vim.wo.diff then vim.cmd.normal({ ']c', bang = true }) else gs.nav_hunk('next') end end, 'Next hunk')
    bmap('n', '[h', function() if vim.wo.diff then vim.cmd.normal({ '[c', bang = true }) else gs.nav_hunk('prev') end end, 'Prev hunk')
    bmap('n', ']H', function() gs.nav_hunk('last') end, 'Last hunk')
    bmap('n', '[H', function() gs.nav_hunk('first') end, 'First hunk')
    bmap({ 'n', 'x' }, '<leader>ghs', ':Gitsigns stage_hunk<cr>', 'Stage hunk')
    bmap({ 'n', 'x' }, '<leader>ghr', ':Gitsigns reset_hunk<cr>', 'Reset hunk')
    bmap('n', '<leader>ghS', gs.stage_buffer, 'Stage buffer')
    bmap('n', '<leader>ghR', gs.reset_buffer, 'Reset buffer')
    bmap('n', '<leader>ghp', gs.preview_hunk_inline, 'Preview hunk')
    bmap('n', '<leader>ghb', function() gs.blame_line({ full = true }) end, 'Blame line')
    bmap('n', '<leader>ghB', gs.blame, 'Blame buffer')
    bmap('n', '<leader>ghd', gs.diffthis, 'Diff this')
    bmap('n', '<leader>ghD', function() gs.diffthis('~') end, 'Diff this ~')
    bmap('n', '<leader>ub', gs.toggle_current_line_blame, 'Toggle line blame')
    bmap({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<cr>', 'Select hunk')
  end,
})

require('diffview').setup({
  enhanced_diff_hl = true,
  view = {
    default = { layout = 'diff2_horizontal', winbar_info = true },
    merge_tool = { layout = 'diff3_mixed', disable_diagnostics = true },
    file_history = { layout = 'diff2_horizontal', winbar_info = true },
  },
  file_panel = { listing_style = 'tree', win_config = { position = 'left', width = 32 } },
  hooks = {
    diff_buf_read = function(bufnr)
      vim.opt_local.wrap = false
      vim.opt_local.list = false
      vim.opt_local.relativenumber = false
    end,
  },
  -- In the Claude review pane, q closes the whole pane rather than just the view.
  keymaps = (function()
    local q = { 'n', 'q', is_review and '<cmd>qa!<cr>' or '<cmd>DiffviewClose<cr>', { desc = is_review and 'Close review pane' or 'Close diffview' } }
    return { view = { q }, file_panel = { q }, file_history_panel = { q } }
  end)(),
})
map('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Diffview (working tree)' })
map('n', '<leader>gD', '<cmd>DiffviewOpen HEAD~1<cr>', { desc = 'Diffview (last commit)' })
map('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = 'File history' })
map('n', '<leader>gH', '<cmd>DiffviewFileHistory<cr>', { desc = 'Repo history' })
map('n', '<leader>gq', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' })

-- ── Formatting ──────────────────────────────────────────────────────────────
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    go = { 'gofmt' },
    rust = { 'rustfmt' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    fish = { 'fish_indent' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    jsonc = { 'prettierd', 'prettier', stop_after_first = true },
    yaml = { 'prettierd', 'prettier', stop_after_first = true },
    markdown = { 'prettierd', 'prettier', stop_after_first = true },
    css = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    ['_'] = { 'trim_whitespace' },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = function(buf)
    if vim.g.autoformat == false or vim.b[buf].autoformat == false then return end
    return { timeout_ms = 1500 }
  end,
})
map({ 'n', 'x' }, '<leader>cf', function() require('conform').format({ async = true }) end, { desc = 'Format' })
map('n', '<leader>uf', function() vim.g.autoformat = vim.g.autoformat == false; vim.notify('Autoformat ' .. (vim.g.autoformat == false and 'off' or 'on')) end, { desc = 'Toggle autoformat' })

-- ── LSP ─────────────────────────────────────────────────────────────────────
require('lazydev').setup({ library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, 'snacks.nvim' } })
require('fidget').setup({ notification = { window = { winblend = 0, normal_hl = 'Comment' } } })
require('mason').setup({ ui = { border = 'rounded' } })
require('mason-lspconfig').setup({
  ensure_installed = {},
  automatic_enable = true,
})
require('mason-tool-installer').setup({
  ensure_installed = { 'lua-language-server', 'typescript-language-server', 'gopls', 'bash-language-server', 'json-lsp', 'yaml-language-server', 'marksman', 'taplo', 'html-lsp', 'css-lsp', 'stylua', 'prettierd', 'shfmt', 'ruff' },
  run_on_start = true,
  start_delay = 2000,
})

vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
vim.lsp.config('lua_ls', {
  settings = { Lua = { completion = { callSnippet = 'Replace' }, hint = { enable = true }, workspace = { checkThirdParty = false } } },
})
vim.lsp.config('gopls', { settings = { gopls = { hints = { assignVariableTypes = true, parameterNames = true, rangeVariableTypes = true }, gofumpt = true } } })
vim.lsp.config('rust_analyzer', { settings = { ['rust-analyzer'] = { check = { command = 'clippy' }, inlayHints = { lifetimeElisionHints = { enable = 'always' } } } } })
vim.lsp.config('ts_ls', { settings = { typescript = { inlayHints = { includeInlayParameterNameHints = 'literals', includeInlayVariableTypeHints = true } } } })
-- Servers already on PATH outside Mason
for _, s in ipairs({ 'pyright', 'rust_analyzer' }) do
  local bin = ({ pyright = 'pyright-langserver', rust_analyzer = 'rust-analyzer' })[s]
  if vim.fn.executable(bin) == 1 then vim.lsp.enable(s) end
end
if vim.fn.executable('fish-lsp') == 1 then vim.lsp.enable('fish_lsp') end

-- ── Completion ──────────────────────────────────────────────────────────────
require('blink.cmp').setup({
  keymap = { preset = 'enter', ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' }, ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' } },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = 'rounded' } },
    menu = { border = 'rounded', draw = { treesitter = { 'lsp' }, columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'kind' } } } },
    ghost_text = { enabled = true },
    list = { selection = { preselect = false, auto_insert = true } },
  },
  signature = { enabled = true, window = { border = 'rounded' } },
  sources = {
    default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
    providers = { lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 } },
  },
  cmdline = { enabled = true, keymap = { preset = 'cmdline' }, completion = { menu = { auto_show = true } } },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
})

-- ── Markdown ────────────────────────────────────────────────────────────────
require('render-markdown').setup({ file_types = { 'markdown', 'codecompanion', 'Avante' }, code = { style = 'full', width = 'block', left_pad = 1, right_pad = 1 }, heading = { icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' } } })

-- ── Claude Code ─────────────────────────────────────────────────────────────
-- Claude runs in a kitty split beside Neovim (not a nvim terminal). Edits made
-- by Claude arrive as live diffs in this Neovim via the IDE protocol.
-- Each Neovim owns one Claude window, tagged with this Neovim's kitty window id,
-- so <leader>ac focuses the Claude connected to *this* editor, not one in another tab.
local function kitty_claude_cmd(cmd, env)
  local me = vim.env.KITTY_WINDOW_ID
  if not vim.env.KITTY_LISTEN_ON or not me then return 'kitty --title claude -e ' .. cmd end
  local match = 'var:role=claude and var:nvim_win=' .. me
  local existing = vim.system({ 'kitten', '@', 'ls', '--match', match }, { text = true }):wait()
  if existing.code == 0 and existing.stdout:match('"id"') then
    return { 'kitten', '@', 'focus-window', '--match', match }
  end
  local parts = {
    'kitten', '@', 'launch', '--type=window', '--match=window_id:' .. me, '--next-to=id:' .. me, '--location=vsplit', '--bias=42',
    '--cwd=' .. vim.fn.getcwd(), '--title=claude', '--var=role=claude', '--var=nvim_win=' .. me,
  }
  for k, v in pairs(env or {}) do parts[#parts + 1] = '--env=' .. k .. '=' .. tostring(v) end
  vim.list_extend(parts, require('claudecode.utils').parse_command(cmd))
  return parts
end

require('claudecode').setup({
  auto_start = not is_review,
  log_level = 'warn',
  track_selection = true,
  terminal = {
    provider = 'external',
    provider_opts = { external_terminal_cmd = kitty_claude_cmd },
  },
  diff_opts = { layout = 'vertical', open_in_new_tab = false, keep_terminal_focus = false },
})
map('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = 'Launch / focus Claude (kitty split)' })
map('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = 'Focus Claude' })
map('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = 'Resume Claude' })
map('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = 'Continue Claude' })
map('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'Select model' })
map('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'Add buffer to context' })
map('x', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send selection' })
map('n', '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>', { desc = 'Add file (explorer)' })
map('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'Accept diff' })
map('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'Deny diff' })
map('n', '<leader>aS', '<cmd>ClaudeCodeStatus<cr>', { desc = 'Status' })
map('n', '<leader>ax', '<cmd>ClaudeCodeStop<cr>', { desc = 'Stop server' })
-- Review pane (nvim+diffview that Claude's hook drives) is in lua/claude_review.lua
require('claude_review')

-- Notify when a Claude diff opens so it is obvious even if you are elsewhere
vim.api.nvim_create_autocmd('User', {
  pattern = 'ClaudeCodeDiffOpened',
  callback = function(ev)
    local f = ev.data and ev.data.file_path or '?'
    vim.notify('Claude proposes changes to ' .. vim.fn.fnamemodify(f, ':~:.') .. '\n<leader>aa accept · <leader>ad deny', vim.log.levels.INFO, { title = 'Claude Code' })
  end,
})

-- ── Statusline ──────────────────────────────────────────────────────────────
local function claude_status()
  local ok, cc = pcall(require, 'claudecode')
  if not ok or not cc.state or not cc.state.server then return '' end
  -- Only shown once Claude is attached; the listening port alone isn't useful.
  local connected = cc.is_claude_connected and cc.is_claude_connected() or false
  return connected and '✦ ✓' or ''
end
local function lsp_names()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[#names + 1] = c.name end
  return #names > 0 and (' ' .. table.concat(names, ' ')) or ''
end
require('lualine').setup({
  options = {
    theme = 'catppuccin-macchiato',
    globalstatus = true,
    component_separators = { left = '\u{e0b5}', right = '\u{e0b7}' },
    section_separators = { left = '\u{e0b4}', right = '\u{e0b6}' },
    disabled_filetypes = { statusline = { 'snacks_dashboard' } },
  },
  sections = {
    lualine_a = { { 'mode', fmt = function(s) return s:sub(1, 3) end } },
    lualine_b = { 'branch', { 'diff', symbols = { added = '+', modified = '~', removed = '-' } } },
    lualine_c = {
      { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
      { 'filename', path = 1, symbols = { modified = '●', readonly = '\u{f023}', unnamed = '[scratch]' } },
      { 'diagnostics', symbols = { error = '\u{f057} ', warn = '\u{f071} ', info = '\u{f05a} ', hint = '\u{f0eb} ' } },
    },
    lualine_x = {
      { claude_status, color = { fg = '#c6a0f6', gui = 'bold' } },
      -- profiler.status() is itself a lualine component spec (shown only while profiling).
      require('snacks').profiler.status(),
      { lsp_names, color = { fg = '#8aadf4' } },
    },
    lualine_y = { { 'progress', separator = ' ', padding = { left = 1, right = 0 } }, { 'location', padding = { left = 0, right = 1 } } },
    lualine_z = { { function() return os.date('%H:%M') end } },
  },
  extensions = { 'trouble', 'mason', 'lazy', 'quickfix', 'man' },
})
