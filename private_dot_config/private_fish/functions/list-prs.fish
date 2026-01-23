function list-prs --description 'Prints all PR URLs for the current branch and copies them to clipboard'
    set -l current_branch (git branch --show-current)
    set -l pr_list (gh pr list --head "$current_branch" --json baseRefName,url --jq '.[] | "[\(.baseRefName)]: \(.url)"')

    if test -n "$pr_list"
        echo "Found PRs for '$current_branch':"

        # Print each PR found
        for pr in $pr_list
            echo "$pr"
        end

        string join \n $pr_list | pbcopy
        echo -e "\n(Copied list to clipboard)"
    else
        echo "Could not find any PRs for branch '$current_branch'."
    end
end
