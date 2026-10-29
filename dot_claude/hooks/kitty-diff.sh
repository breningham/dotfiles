#!/bin/sh
# Claude Code PostToolUse hook (Edit|Write|MultiEdit).
# Keeps one live review pane (kitty split running Neovim + Diffview) next to the
# Claude window that made the edit, and jumps it to the edited line. Focus stays
# on Claude. The pane is found by kitty user vars in Claude's own tab: role=review
# (set at launch) and review_sock (published by the pane's Neovim), so a pane
# opened by hand with Ctrl+Shift+A r is reused too, and Claude sessions in other
# tabs get their own panes. If Claude was launched from Neovim (claudecode.nvim,
# IDE protocol) the diff is already shown inside that Neovim, so this does nothing.
# Only files inside a git repo count, plus plan-mode plans in ~/.claude/plans.
[ -n "$KITTY_LISTEN_ON" ] && [ -n "$KITTY_WINDOW_ID" ] || exit 0
[ -n "$CLAUDE_CODE_SSE_PORT" ] && exit 0
command -v nvim >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -f "$file" ] || exit 0
root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null)
if [ -z "$root" ]; then
  # Plan-mode plans live outside any repo; the pane shows them rendered as docs.
  case $file in
    "$HOME"/.claude/plans/*.md) root=$(dirname "$file") ;;
    *) exit 0 ;;
  esac
fi

# Line to jump to: find the longest line of the new text in the file, minus its
# offset within that text. 0 means "first hunk" (whole-file Write).
line=0
set -- $(printf '%s' "$input" | jq -r '
  (.tool_input.new_string // .tool_input.edits[-1].new_string // empty)
  | split("\n") | to_entries | map(select(.value | test("\\S")))
  | max_by(.value | length) // empty | "\(.key) \(.value | gsub("^\\s+|\\s+$"; "") | @base64)"')
if [ $# -eq 2 ]; then
  needle=$(printf '%s' "$2" | base64 -d)
  hit=$(grep -nF -m1 -- "$needle" "$file" | cut -d: -f1)
  [ -n "$hit" ] && line=$((hit - $1)) && [ "$line" -lt 1 ] && line=1
fi

esc=$(printf '%s' "$file" | sed "s/'/''/g")
call="ClaudeReview.refresh('$esc', $line)"

# Parallel edits fire this hook concurrently; without a lock each run sees no
# pane yet and launches its own. mkdir is atomic and, unlike flock, on macOS.
# A lock older than ~3s is from a killed run, so take it over.
lock="${TMPDIR:-/tmp}/claude-review-${KITTY_PID:-0}-$KITTY_WINDOW_ID.lock"
tries=30
until mkdir "$lock" 2>/dev/null; do
  tries=$((tries - 1))
  [ "$tries" -le 0 ] && break
  sleep 0.1
done
trap 'rmdir "$lock" 2>/dev/null' EXIT

pane=$(kitten @ ls --match-tab "window_id:$KITTY_WINDOW_ID" 2>/dev/null | jq -r '
  [.[].tabs[].windows[] | select(.user_vars.role == "review")][0]
  | if . then "found \(.user_vars.review_sock // "")" else empty end')

if [ -n "$pane" ]; then
  sock=${pane#found }
  # No socket yet means the pane is still starting; it opens Diffview itself.
  [ -n "$sock" ] && nvim --server "$sock" --remote-expr "v:lua.$call" >/dev/null 2>&1
  exit 0
fi

kitten @ launch --type=window --match "window_id:$KITTY_WINDOW_ID" --next-to "id:$KITTY_WINDOW_ID" --location=vsplit --bias=58 \
  --keep-focus --title claude-review --var role=review --cwd "$root" \
  nvim --cmd 'let g:claude_review = 1' -c "call v:lua.$call" >/dev/null 2>&1
exit 0
