function gr --description 'Jump to the root of the current git worktree'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gr"
        echo ""
        echo "Description:"
        echo "  Jumps to the root directory of the CURRENT worktree."
        echo "  Useful when deep inside subdirectories (e.g. apps/web/src)."
        return 0
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$root"
        echo "  Jumping to worktree root..."
        cd $root
    else
        echo "  Error: Not inside a git repository."
        return 1
    end
end
