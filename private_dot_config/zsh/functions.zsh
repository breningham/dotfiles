#!/bin/zsh

function edit_zsh_config() {
	$EDITOR -p "$ZDOTDIR/.zshrc" "$ZDOTDIR/plugins.zsh" "$ZDOTDIR/functions.zsh" "$ZDOTDIR/aliases.zsh" && source "$ZDOTDIR/.zshrc" 
}

function edit_tmux_config() {
	$EDITOR ~/.config/tmux/tmux.conf && tmux source "~/.config/tmux/tmux.conf"
}

function edit_zsh_plugins() {
	local plugin_file="$ZDOTDIR/plugins.txt"
	$EDITOR $plugin_file && antidote load $plugin_file;
}

function reload_zsh_config() {
	source "$ZDOTDIR/.zshrc"
}

function edit_vim_config() {
    $EDITOR ~/.config/nvim 
}

# Start an HTTP server from a directory, optionally specifying the port
function httpserver() {
  local port="${1:-8000}";
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}
