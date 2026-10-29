#!/bin/sh
# Claude Code lifecycle hook: records this session's state on its kitty window as
# the user var claude_state, which ~/.config/kitty/tab_bar.py shows as a tab badge.
# Usage: kitty-status.sh busy|waiting|done|clear   (hook JSON arrives on stdin)
[ -n "$KITTY_LISTEN_ON" ] && [ -n "$KITTY_WINDOW_ID" ] || exit 0
state=$1
input=$(cat)
if [ "$state" = waiting ]; then
  # Idle reminders ("waiting for your input") come after Stop; keep showing done.
  kind=$(printf '%s' "$input" | jq -r '.notification_type // .message // ""' 2>/dev/null)
  case $kind in idle_prompt|*"waiting for your input"*) exit 0 ;; esac
fi
var="claude_state=$state"
[ "$state" = clear ] && var=claude_state  # bare name unsets
kitten @ set-user-vars --match "id:$KITTY_WINDOW_ID" "$var" >/dev/null 2>&1
exit 0
