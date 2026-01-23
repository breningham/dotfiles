function gwaz --description 'Create a worktree and replace current Zed window'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwaz <new-branch> [source-branch]"
        echo ""
        echo "Description:"
        echo "  Wrapper around 'gwa' that creates a new worktree,"
        echo "  then REPLACES the current Zed workspace with the new one."
        return 0
    end

    # 1. Call your existing 'gwa' function
    # We capture the status to ensure we only switch Zed if creation succeeded
    gwa $argv

    # 2. If 'gwa' was successful, reuse the Zed window
    if test $status -eq 0
        echo "zed  Updating Zed workspace..."
        zed -r .
    end
end
