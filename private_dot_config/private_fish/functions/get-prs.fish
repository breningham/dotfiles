function get-prs -d "Lists PRs for a branch across all base branches"
    set -l branch $argv[1]

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set_color red; echo "Error: Not a git repository."; set_color normal
        return 1
    end

    if test -z "$branch"
        set branch (git branch --show-current)
    end

    if not gh auth status >/dev/null 2>&1
        set_color yellow; echo "Error: GitHub CLI (gh) not authenticated."; set_color normal
        return 1
    end

    set -l output (gh pr list --head "$branch" --json baseRefName,url --template '{{range .}}* {{.baseRefName}}: {{.url}}{{"\n"}}{{end}}')

    if test -z "$output"
        set_color blue; echo "No open PRs found for branch: $branch"; set_color normal
        return 0
    end

    echo "$output"
end
