function gw --description 'Fuzzy find and switch to a git worktree'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gw"
        echo ""
        echo "Description:"
        echo "  Opens an interactive list (using fzf) of all active worktrees."
        echo "  Select one to immediately 'cd' into it."
        echo ""
        echo "Requirements:"
        echo "  - fzf (install via brew/apt)"
        return 0
    end

    set -l selected (git worktree list | fzf --height 40% --layout=reverse --border)
    if test -n "$selected"
        set -l target_path (echo $selected | awk '{print $1}')
        echo "  Switching to worktree..."
        cd $target_path
    end
end
