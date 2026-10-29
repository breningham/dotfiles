-- Live review pane. ~/.claude/hooks/kitty-diff.sh launches `nvim --cmd 'let
-- g:claude_review=1' -c 'call v:lua.ClaudeReview.open(file, line)'` in a kitty
-- split beside Claude the first time Claude edits a file. On start this Neovim
-- publishes v:servername as the kitty user var `review_sock`, so the hook (and a
-- pane opened by hand with Ctrl+Shift+A r) can be found again with `kitten @ ls`.
-- Later edits call ClaudeReview.refresh(file, line) via --remote-expr: the
-- Diffview is refreshed, the edited file selected and the edited line flashed.
-- An edit in a different git repo reopens the Diffview in that repo, and an edit
-- to a Markdown doc shows the doc rendered (in its own tabpage) instead of a diff.
local M = {}

local ns = vim.api.nvim_create_namespace('claude_review')
local pending = {} -- edits that arrived during the debounce window
local timer = assert(vim.uv.new_timer())

local function relpath(file)
  local root = vim.fs.root(file, '.git') or vim.fn.getcwd()
  return vim.fs.relpath(root, file) or file, root
end

-- git reports resolved paths (/private/tmp, not /tmp), so compare real paths.
local function same_dir(a, b)
  if not a or not b then return false end
  return (vim.uv.fs_realpath(a) or a) == (vim.uv.fs_realpath(b) or b)
end

-- Find the window showing the working-tree copy of `file` (Diffview's right side).
local function file_win(file)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == file then return win end
  end
end

-- set_file is async inside Diffview, so poll briefly for the window to appear.
local function reveal(file, line, tries)
  tries = tries or 20
  local win = file_win(file)
  if not win then
    if tries > 0 then vim.defer_fn(function() reveal(file, line, tries - 1) end, 50) end
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  line = tonumber(line) or 0
  if line < 1 then
    -- Whole-file write: land on the first hunk.
    vim.api.nvim_win_call(win, function() vim.cmd('normal! gg'); if vim.wo.diff then pcall(vim.cmd, 'normal! ]c') end end)
    line = vim.api.nvim_win_get_cursor(win)[1]
  end
  line = math.min(line, vim.api.nvim_buf_line_count(buf))
  pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
  vim.api.nvim_win_call(win, function() vim.cmd('normal! zz') end)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.hl.range(buf, ns, 'IncSearch', { line - 1, 0 }, { line - 1, -1 }, { timeout = 900 })
end

local function select_file(view, file, line)
  local rel = relpath(file)
  pcall(view.set_file_by_path, view, rel, false, true)
  reveal(file, line)
end

-- Markdown docs (plans, specs, READMEs) are shown rendered by render-markdown
-- instead of diffed. That also covers docs git ignores, which Diffview never lists.
local doc_tab -- the tabpage that shows docs; Diffview keeps its own tabpage

local function is_doc(file)
  return file:match('%.md$') or file:match('%.markdown$')
end

local function blank_tab()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local buf = vim.api.nvim_win_get_buf(wins[1])
  return #wins == 1 and vim.api.nvim_buf_get_name(buf) == '' and not vim.bo[buf].modified
end

local function show_doc(file, line)
  if doc_tab and vim.api.nvim_tabpage_is_valid(doc_tab) then
    vim.api.nvim_set_current_tabpage(doc_tab)
  else
    if not blank_tab() then vim.cmd('tabnew') end
    doc_tab = vim.api.nvim_get_current_tabpage()
  end
  pcall(vim.cmd.edit, vim.fn.fnameescape(file)) -- re-reads the file if it is already open
  reveal(file, line)
end

-- The Diffview may sit in a tabpage other than the current one (the doc tab).
local function find_view(lib)
  local view = lib.get_current_view()
  if view then return view end
  for _, v in ipairs(lib.views) do
    if vim.api.nvim_tabpage_is_valid(v.tabpage) then
      vim.api.nvim_set_current_tabpage(v.tabpage)
      return v
    end
  end
end

local function show_diff(file, line)
  local ok, lib = pcall(require, 'diffview.lib')
  if not ok then return end
  local root = select(2, relpath(file))
  local view = find_view(lib)
  -- Claude moved on to another repo (a sibling service in a multi-repo workspace,
  -- another worktree): reopen the Diffview there rather than refresh the old one.
  if view and not same_dir(view.adapter and view.adapter.ctx.toplevel, root) then
    vim.cmd('DiffviewClose')
    view = nil
  end
  if not view then
    vim.cmd.cd(root)
    -- Explicit -C: Diffview otherwise prefers the current buffer's repo (a doc's).
    vim.cmd('DiffviewOpen -C' .. vim.fn.fnameescape(root))
    view = lib.get_current_view()
  end
  if view then
    view.emitter:once('files_updated', function() vim.schedule(function() select_file(view, file, line) end) end)
    view:update_files() -- debounced, so harmless right after DiffviewOpen
  end
end

local function flush()
  local edits = pending
  pending = {}
  if #edits == 0 then return end
  local last = edits[#edits]
  vim.cmd('silent! checktime')

  if is_doc(last.file) then
    show_doc(last.file, last.line)
  else
    show_diff(last.file, last.line)
  end

  local names, seen = {}, {}
  for _, e in ipairs(edits) do
    local rel = relpath(e.file)
    if not seen[rel] then seen[rel] = true; names[#names + 1] = rel end
  end
  vim.notify(table.concat(names, '\n'), vim.log.levels.INFO, { id = 'claude_review', title = '✦ Claude edited' })
end

-- Edits often land in bursts (MultiEdit, several Writes); coalesce them.
function M.refresh(file, line)
  pending[#pending + 1] = { file = file, line = line }
  timer:stop()
  timer:start(120, 0, vim.schedule_wrap(flush))
  return 'ok'
end

M.open = M.refresh

-- Tell kitty where to reach us. Runs in this window, so no --match needed.
local function publish_socket()
  if not vim.env.KITTY_WINDOW_ID or vim.v.servername == '' then return end
  vim.system({ 'kitten', '@', 'set-user-vars', 'review_sock=' .. vim.v.servername })
end

if vim.g.claude_review == 1 then
  vim.o.laststatus = 3
  vim.o.showtabline = 0
  vim.o.relativenumber = false
  -- After startup so headless/scripted runs (no UI) never claim the pane role.
  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function()
    if #vim.api.nvim_list_uis() > 0 then publish_socket() end
  end })
  local close = function() vim.cmd('qa!') end
  vim.keymap.set('n', 'q', close, { desc = 'Close review pane' })
  vim.keymap.set('n', 'R', '<cmd>DiffviewRefresh<cr>', { desc = 'Refresh' })
end

_G.ClaudeReview = M
return M
