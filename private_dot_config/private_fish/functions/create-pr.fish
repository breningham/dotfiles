function create-pr -d "Creates a single PR via gh cli"
    argparse 't/title=' 'b/body=' 'e/env=' 'base=' 'draft' -- $argv
    or return 1

    set -q _flag_base; or set -l _flag_base "main"
    set -l draft_flag; set -q _flag_draft; and set draft_flag "--draft"

    gh pr create \
        --title "$_flag_title [$_flag_env]" \
        --body "$_flag_body" \
        --base "$_flag_base" \
        $draft_flag && echo "Created PR for $_flag_env"
end
