function create-pr -d "Creates a single PR via gh cli"
    argparse 't/title=' 'b/body=' 'e/env=' 'base=' 'draft' -- $argv
    or return 1

    # Default values
    set -q _flag_base; or set -l _flag_base "main"
    set -l draft_flag; set -q _flag_draft; and set draft_flag "--draft"

    # Handle optional environment suffix for the title
    set -l title_suffix ""
    if test -n "$_flag_env"
        set title_suffix " [$_flag_env]"
    end

    gh pr create \
        --title "$_flag_title$title_suffix" \
        --body "$_flag_body" \
        --base "$_flag_base" \
        $draft_flag && echo "Created PR"(test -n "$_flag_env"; and echo " for $_flag_env")
end
