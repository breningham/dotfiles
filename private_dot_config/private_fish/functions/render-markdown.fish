function render-markdown
    if type -q glow
        cat | glow
    else if type -q bat
        cat | bat -l md --plain
    else
        cat
    end
end
