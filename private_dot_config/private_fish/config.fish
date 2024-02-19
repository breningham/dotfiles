if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx VOLTA_HOME "$HOME/.volta"

fish_add_path "$VOlTA_HOME/bin"

set -gx SPICETIFY_HOME "$HOME/.spicetify"

if test -d "$SPICEIFY_HOME"
    fish_add_path "$SPICETIFY_HOME"
end
