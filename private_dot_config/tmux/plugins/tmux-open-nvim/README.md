# tmux-open-nvim

A tmux plugin that helps opening files in a Neovim pane

## Demo

(click thumbnail)

<a href="https://asciinema.org/a/549092?speed=1.5"><img src="https://asciinema.org/a/549092.png" width="300"/></a>

## Installation

Using TPM, add this to your `.tmux.conf`

```shell
set -g @plugin 'trevarj/tmux-open-nvim'
```

Reload tmux config (`<prefix>-I`). Also you may want to start a fresh session to
reload `$PATH` into your environment.

### Create symlink to `ton` script (optional)
Due to the caveat below, you can create a symlink to the `ton` script so it can
be used no matter what.

```shell
# Use any path that is on your $PATH
$ sudo ln -s ~/.tmux/plugins/tmux-open-nvim/scripts/ton /usr/local/bin/ton
```

## Usage

### CLI

The plugin will add a helper script called `ton` to your path while
inside a tmux session.

The target use case of this plugin is when you have a tmux window that already
has a pane running `nvim` and a pane with a terminal:

```shell
$ ton file.txt # optionally add :[line]:[col] to the end, i.e file.txt:40:5
# Opens file.txt in nvim pane
```

#### Caveat

Upon launch of a fresh tmux session, the script will not be in the first pane
due to how an environment is loaded, I guess. I think the only way to resolve this
is by adding the `~/.tmux/plugins/tmux-open-nvim/scripts` directory to your path
permanently or with `tmux -e PATH=$PATH:~/.tmux/plugins/tmux-open-nvim/scripts`

> When you create a session, it creates window 0 automatically, which fires off a shell.
> So, for that shell, setenv doesn't work and you have to send-keys.
> But when you create a new window, like with split-window, the new window gets the environment from the setenv.
> The example shows that both windows have the environment whether set explicitly via export or via setenv.

See:
  - [Info](https://stackoverflow.com/a/49395839/506517)
  - [More Info](https://stackoverflow.com/a/49395839/506517)
  - [No env var restoration with tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect/issues/312)

### tmux-fingers (or tmux-open)

An optimal workflow using [tmux-fingers](https://github.com/Morantron/tmux-fingers):

Add this to your `.tmux.conf`:

```shell
# Overrides matching file paths with :[line]:[col] at the end
set -g @fingers-pattern-0 "((^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]+)(:[[:digit:]]*:[[:digit:]]*)?"
# Launches helper script on Ctrl+[key] in fingers mode
set -g @fingers-ctrl-action "xargs -I {} tmux run-shell 'cd #{pane_current_path}; ~/.tmux/plugins/tmux-open-nvim/scripts/ton {} > ~/.tmux/plugins/tmux-open-nvim/ton.log'"s
```

Now you can enter fingers mode and use `Ctrl+[key]` to launch a file in `nvim`

## Future Features

- [ ] A fzf-like selector that can target exactly which neovim instance you want to open a file in
- [ ] Fix "caveat" above (maybe?)
