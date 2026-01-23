#!/bin/fish

function serve -a directory -d "Uses python to serve a directory"
    set -l options h/help "p/port=" "b/bind="
    argparse -n serve --max-args=1 $options -- $argv
    or return

    if set -q _flag_h
        echo "Usage: serve [-p|--port PORT] [-b|--bind BIND] [DIRECTORY]"
        return
    end

    if not set -q _flag_port
        set -g _flag_port 8000
    end

    if not set -q _flag_bind
        set -g _flag_bind 127.0.0.1
    end

    if not set -q directory
        set directory .
    end

    echo "Serving \"$directory\" on $_flag_bind:$_flag_port"
    python -m http.server $_flag_port -b $_flag_bind -d $directory --protocol HTTP/1.1
end
