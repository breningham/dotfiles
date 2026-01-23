
function create-prs -a title -d "Creates PR's for dev, staging and production";
    create-pr "$title" "dev" "develop"
    create-pr "$title" "staging" "staging" --draft
    create-pr "$title" "production" --draft
end;

function create-pr -a title env base -d "Creates a PR for the specified environment";
    set -l draft_flag

    if contains -- "--draft" $argv
        set draft_flag "--draft"
    end

    if not test -n "$base"
        set base "main"
    end

    gh pr create --fill --base "$base" --title "$title [$env]" $draft_flag && echo "Created PR for $env"
end;
