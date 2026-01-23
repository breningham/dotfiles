function gwa --description 'Create a new git worktree, optionally from a source branch'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwa <new-branch> [source-branch]"
        echo ""
        echo "Examples:"
        echo "  gwa feature/login            # Create from current HEAD"
        echo "  gwa feature/login develop    # Create 'feature/login' based on 'develop'"
        echo ""
        echo "Description:"
        echo "  Creates a new folder and a new branch in your worktree setup,"
        echo "  then automatically switches into that directory."
        return 0
    end

    set -l new_branch $argv[1]
    set -l source_ref $argv[2]

    if test -z "$new_branch"
        echo "  Error: Missing branch name."
        echo "Try: gwa --help"
        return 1
    end

    set -l common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$common_dir"
        echo "  Error: You are not inside a git worktree setup."
        return 1
    end
    set -l root_dir (dirname (realpath $common_dir))
    set -l target_path "$root_dir/$new_branch"

    if git rev-parse --verify --quiet $new_branch >/dev/null
        echo "  Branch '$new_branch' already exists. Adding worktree..."
        git worktree add $target_path $new_branch
    else if test -n "$source_ref"
        echo "  Creating worktree '$new_branch' based on '$source_ref'..."
        git worktree add -b $new_branch $target_path $source_ref
    else
        echo "  Creating worktree '$new_branch'..."
        git worktree add -b $new_branch $target_path
    end

    if test $status -eq 0
        cd $target_path
        git config --local push.autoSetupRemote true

        echo "  Switching to $target_path"
    end
end
