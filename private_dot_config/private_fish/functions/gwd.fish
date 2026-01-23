function gwd --description 'Delete a git worktree safely'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwd <folder-name>"
        echo ""
        echo "Example:"
        echo "  gwd feature/login"
        echo ""
        echo "Description:"
        echo "  Safely removes a worktree folder and forces branch deletion."
        echo "  Must be run from a sibling directory (e.g. from 'gsr' root)."
        return 0
    end

    set -l branch_name $argv[1]

    if test -z "$branch_name"
        echo "  Error: Missing folder name."
        echo "Try: gwd --help"
        return 1
    end

    set -l common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$common_dir"
        echo "  Error: You are not inside a git worktree setup."
        return 1
    end
    set -l root_dir (dirname (realpath $common_dir))
    set -l target_path "$root_dir/$branch_name"

    if not test -d "$target_path"
        echo "  Error: Worktree '$branch_name' not found at $target_path"
        return 1
    end

    if test "$target_path" = (pwd)
        echo "  Error: You cannot delete the worktree you are currently inside."
        echo "Run 'gsr' to go to the root first."
        return 1
    end

    read -P " Delete worktree '$branch_name' and force remove branch? [y/N] " -l confirm
    if test "$confirm" != "y"
        return
    end

    git worktree remove --force $target_path
    if test $status -eq 0
        echo "  Worktree deleted."
    end
end
