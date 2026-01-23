if status is-interactive
    # 1. Initialize Mise (Node, Bitwarden CLI, etc)
    mise activate fish | source

    # 2. Bitwarden Unlock Helper
    function bw-unlock
        set -gx BW_SESSION (bw unlock --raw)
        echo "Bitwarden unlocked for this session."
    end

    # 3. Starship (Optional, but recommended for visual context)
    starship init fish | source
end
