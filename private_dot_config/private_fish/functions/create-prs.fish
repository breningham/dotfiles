function create-prs -d "Creates PRs for dev, staging, and production"
    argparse 't/title=' 'b/body=' 'dry-run' -- $argv
    or return 1

    set -l title $_flag_title
    set -l ticket (__get_ticket_id)

    # Auto-prepend ticket if missing from title
    if test -n "$ticket"; and test -n "$title"
        if not string match -qi "*$ticket*" "$title"
            set title "$ticket: $title"
        end
    end

    # Handle body from flag or pipe
    set -l body $_flag_body
    if not set -q _flag_body
        if not isatty stdin
            # Use read -z to swallow stdin until EOF without hanging
            read -z body
        else
            set body ""
        end
    end

    if set -q _flag_dry_run
        echo "------------------------"
        set_color cyan --bold; echo "TITLE: $title"; set_color normal
        echo "$body" | render-markdown
        echo "------------------------"
        return 0
    end

    # Pass body explicitly to avoid create-pr trying to read stdin again
    create-pr --title "$title" --body "$body" --env "dev" --base "develop"
    create-pr --title "$title" --body "$body" --env "staging" --base "staging" --draft
    create-pr --title "$title" --body "$body" --env "production" --base "main" --draft

    if isatty stdout
        echo -e "\n"(set_color green --bold)"PRs created!"(set_color normal)
        echo "$body" | render-markdown
    end
end
