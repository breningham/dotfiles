# Chezmoi Dotfiles

This repository contains my personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Structure

- `.chezmoidata.yaml`: Centralized configuration and identity data.
- `.chezmoiignore`: Files to be ignored by chezmoi.
- `dot_gitconfig.tmpl`: Git configuration template.
- `private_dot_config/`: Application-specific configurations (Fish, Ghostty, Mise, etc.).

## Usage

To apply these dotfiles:

```bash
chezmoi apply
```
