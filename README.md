# Chezmoi Dotfiles

This repository contains my personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Structure

- `.chezmoidata.yaml`: Centralized configuration and identity data.
- `.chezmoiignore`: Files to be ignored by chezmoi.
- `dot_gitconfig.tmpl`: Git configuration template.
- `private_dot_config/`: Application-specific configurations (Fish, Ghostty, Mise, etc.).
- `private_dot_config/kitty/`: kitty. `kitty.conf` is shared and ends with `include ${KITTY_OS}.conf`, so
  OS differences live in `linux.conf` / `macos.conf` rather than a template (templates can't be symlinked).
  `tab_bar.py` turns its KDE-only window buttons off on macOS.
- `private_dot_config/nvim/`: Neovim 0.12 (`vim.pack`; the lock file is tracked and updated in place).
- `dot_claude/hooks/`: Claude Code hooks for the kitty review pane and tab badges. Stored non-executable
  (executables can't be symlinked) and run via `sh`.
- `dot_claude/modify_private_settings.json`: merges those hook entries into `~/.claude/settings.json` with `jq`,
  leaving everything else Claude Code writes there alone.
- `.chezmoi.toml.tmpl`: turns on symlink mode (see below).

## Usage

To apply these dotfiles:

```bash
chezmoi apply
```

## Symlink mode

`chezmoi init` writes `mode = "symlink"` into the local config, so plain files are symlinks into this repo:
editing `~/.config/nvim/...` or `~/.config/kitty/...` edits the repo directly, and there is nothing to `re-add`.
Templates, `private_`, `executable_` and `modify_` files are still written as real files, so after editing one of
those in place, run `chezmoi re-add` (or edit it with `chezmoi edit`). To publish changes:

```bash
chezmoi git -- add -A && chezmoi git -- commit -m "..." && chezmoi git -- push
```

