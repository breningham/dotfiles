function gwz --description 'Fuzzy find a worktree and replace current Zed window'
    if contains -- -h $argv; or contains -- --help $argv
        echo "  Usage: gwz"
        echo ""
        echo "Description:"
        echo "  Interactive list (fzf) to switch worktrees,"
        echo "  then REPLACES the current Zed workspace with the selection."
        return 0
    end

    # 1. Run the interactive selection
    set -l selected (git worktree list | fzf --height 40% --layout=reverse --border)

    if test -n "$selected"
        set -l target_path (echo $selected | awk '{print $1}')

        # 2. Switch directory in the terminal
        echo "  Switching shell to $target_path"
        cd $target_path

        # 3. Reuse the Zed window
        echo "zed  Updating Zed workspace..."
        zed -r .
    end
end
