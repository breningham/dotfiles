function create-prs-manual -d "Creates PR's for dev, staging and production manually"
    argparse 'd/dry-run' -- $argv
    or return

    set -l title $argv[1]
    set -l description $argv[2]

    if test -z "$title"
        echo (set_color red)"Usage: create-prs-manual <title> [description] [--dry-run]"(set_color normal)
        return 1
    end

    # Default description to title if empty
    if test -z "$description"
        set description "$title"
    end

    # Helper function (scoped to this execution if we delete it after, or we can just define it)
    # Using a unique name to avoid conflicts
    function _cpm_create_pr -a pr_title pr_env pr_base pr_body
        set -l target_base (test -n "$pr_base"; and echo "$pr_base"; or echo "main")
        set -l opts --title "$pr_title [$pr_env]" --base "$target_base"

        if test -n "$pr_body"
            set -a opts --body "$pr_body"
        else
            set -a opts --fill
        end

        # Check for --draft in the arguments passed to this helper
        if contains -- "--draft" $argv
            set -a opts --draft
        end

        gh pr create $opts; and echo "Created PR for $pr_env"; or echo "Failed to create PR for $pr_env"
    end

    if set -q _flag_dry_run
        echo "------------------------"
        set_color blue --bold; echo "TITLE: "; set_color normal; echo "$title"
        echo
        set_color blue --bold; echo "DESCRIPTION: "; set_color normal
        echo "$description"
        echo "------------------------"
    else
        _cpm_create_pr "$title" "dev"        "develop" "$description"
        _cpm_create_pr "$title" "staging"    "staging" "$description" --draft
        _cpm_create_pr "$title" "production" "main"    "$description" --draft
    end

    functions -e _cpm_create_pr
end
