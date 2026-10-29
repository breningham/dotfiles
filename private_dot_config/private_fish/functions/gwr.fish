function gwr --description 'Remove a git worktree and its branch'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwr <branch>"
        echo ""
        echo "Examples:"
        echo "  gwr feature/ABC-123"
        echo ""
        echo "Description:"
        echo "  Removes the worktree for the given branch, deletes the local branch,"
        echo "  and updates the VSCode workspace file."
        return 0
    end

    set -l branch $argv[1]

    if test -z "$branch"
        echo "  Error: Missing branch name."
        echo "  Try: gwr --help"
        return 1
    end

    set -l common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$common_dir"
        echo "  Error: You are not inside a git worktree setup."
        return 1
    end

    set -l root_dir (dirname (realpath $common_dir))
    set -l target_path "$root_dir/$branch"

    if not test -d "$target_path"
        echo "  Error: No worktree found at '$target_path'."
        return 1
    end

    # If we're currently inside the worktree being removed, go to root first
    if string match -q "$target_path*" (pwd)
        echo "  Switching to $root_dir before removal..."
        cd $root_dir
    end

    echo "  Removing worktree '$branch'..."
    git worktree remove --force $target_path

    if git rev-parse --verify --quiet $branch >/dev/null
        git branch -d $branch 2>/dev/null
            or echo "  ⚠️  Branch '$branch' not fully merged — use 'git branch -D $branch' to force delete."
    end

    # --- EXECUTE HOOKS ---
    set -l root_hook "$root_dir/.hooks/post-worktree-remove.sh"

    if test -x "$root_hook"
        echo "  Running root hook..."
        bash "$root_hook" "$target_path" "$branch"
    end
end
