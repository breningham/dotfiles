function close-prs -d "Closes all open PRs for the current branch"
    set -l branch (git branch --show-current)

    # Get the PR numbers
    set -l pr_numbers (gh pr list --head "$branch" --json number --jq '.[].number')

    if test -z "$pr_numbers"
        echo (set_color yellow)"No open PRs found for $branch."(set_color normal)
        return 0
    end

    for pr in $pr_numbers
        gh pr close "$pr" --comment "Closing via CLI utility"
    end

    echo (set_color green)"Successfully closed all PRs for $branch."(set_color normal)
end
