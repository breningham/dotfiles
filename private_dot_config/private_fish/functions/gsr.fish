function gsr --description 'Jump to the base folder of the worktree setup'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gsr"
        echo ""
        echo "Description:"
        echo "  Jumps to the 'Super Root' (the folder containing all worktrees)."
        echo "  Useful for switching contexts or viewing all active branches."
        return 0
    end

    set -l common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test -n "$common_dir"
        echo "  Jumping to super root..."
        cd (dirname (realpath $common_dir))
    else
        echo "  Error: Not inside a git worktree setup."
        return 1
    end
end
