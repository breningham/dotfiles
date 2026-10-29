# Chezmoi Dotfiles

My dotfiles for the CachyOS desktop and the MacBook, managed by [chezmoi](https://www.chezmoi.io/).

## New machine

```bash
chezmoi init --apply git@github.com:breningham/dotfiles.git
```

`init` asks which identity the machine uses (`personal` or `work`; defaults to work on macOS, personal on
Linux). That choice picks the git email, signing key and SSH auth key. No Bitwarden unlock is needed: only
public keys are used, and they live in `.chezmoidata.yaml`. The private keys stay in the Bitwarden SSH agent.

## Day to day

Symlink mode is on (`.chezmoi.toml.tmpl`), so most managed files are symlinks into this repo. Editing
`~/.config/nvim/...` or `~/.config/kitty/...` edits the repo directly. Templates and `private_`,
`executable_` and `modify_` files are still copied; `dots push` runs `chezmoi re-add` to pick those up.

```fish
dots            # what changed, in the repo and on disk
dots push [msg] # re-add, commit everything, push
dots pull       # chezmoi update: pull and apply
```

## Layout

- `.chezmoidata.yaml`: identities (email + public SSH key) and package lists.
- `.chezmoi.toml.tmpl`: symlink mode, the machine's `profile`, delta for `chezmoi diff`.
- `run_onchange_before_{linux,darwin}-install-packages.sh.tmpl`: install missing packages. They rerun only
  when the package lists change, and never upgrade the system. Linux uses pacman for repo packages,
  paru/yay for `linux-aur`, and flatpak; macOS uses `brew bundle`.
- `run_onchange_after_mise-install.sh.tmpl`, `run_onchange_after_bat-cache.sh.tmpl`: mise runtimes and the bat
  theme cache.
- `private_dot_config/kitty/`: `kitty.conf` is shared and ends with `include ${KITTY_OS}.conf`, so the OS
  differences live in `linux.conf` / `macos.conf` and the files stay symlinks. `tab_bar.py` turns its
  KDE-only window buttons off on macOS.
- `private_dot_config/nvim/`: Neovim 0.12 (`vim.pack`; its lock file is tracked and updated in place).
- `dot_claude/hooks/`: Claude Code hooks for the kitty review pane and tab badges. They are stored
  non-executable, so they stay symlinks, and run via `sh`.
- `dot_claude/modify_private_settings.json`: merges those hook entries into `~/.claude/settings.json` with
  `jq`, leaving everything else Claude Code writes there alone.
- `.chezmoiignore`: per-OS exclusions. Only files in this repo are ever managed, so there's no need to
  allow-list them.
