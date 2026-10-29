function gwaz --description 'Create a worktree and open it in Neovim'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwaz <new-branch> [source-branch]"
        echo ""
        echo "Description:"
        echo "  Wrapper around 'gwa' that creates a new worktree,"
        echo "  then opens Neovim in the new one."
        return 0
    end

    # 1. Call your existing 'gwa' function
    # We capture the status to ensure we only open Neovim if creation succeeded
    gwa $argv

    # 2. If 'gwa' was successful, open Neovim there
    if test $status -eq 0
        nvim .
    end
end
