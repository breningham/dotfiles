function get-pr-url --wraps='gh pr view' --description 'Copies the current branch PR URL to clipboard'
    set -l pr_url (gh pr view --json url --jq ".url")

    if test -n "$pr_url"
        echo "PR: $pr_url"
        echo -n $pr_url | pbcopy
    else
        echo -n "Could not find a PR for this branch."
    end
end
