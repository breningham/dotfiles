function __get_ticket_id
    set -l branch (git branch --show-current 2>/dev/null)
    # Matches the ticket after the slash (e.g., feature/CLICKAPPS-1234)
    string match -r -i '(?<=/)[A-Z]+-[0-9]+' "$branch"
end
