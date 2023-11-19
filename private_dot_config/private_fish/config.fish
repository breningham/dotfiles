if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_add_path "$VOlTA_HOME/bin"

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
