# Dotfiles shortcuts. Files chezmoi manages are mostly symlinks into the source
# dir (symlink mode), so edits are already in the repo; this just ships them.
#   dots            status of the repo and of anything chezmoi would change
#   dots push [msg] commit everything and push
#   dots pull       pull and apply (chezmoi update)
function dots
    switch "$argv[1]"
        case push
            set -l msg $argv[2..-1]
            test -n "$msg"; or set msg "Update dotfiles from "(hostname -s)
            chezmoi re-add; and chezmoi git -- add -A; and chezmoi git -- commit -m "$msg"; and chezmoi git -- push
        case pull
            chezmoi update
        case '' status
            chezmoi git -- status --short
            chezmoi status
        case '*'
            echo "usage: dots [status|push [msg]|pull]" >&2
            return 1
    end
end
