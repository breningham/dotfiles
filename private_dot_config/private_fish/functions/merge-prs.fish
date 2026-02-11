function merge-prs -d "Merges all PRs for the current branch"
    argparse 'y/yes' -- $argv
    set -l branch (git branch --show-current)

    # Get PRs and their base branches
    set -l prs (gh pr list --head "$branch" --json number,baseRefName --jq '.[] | "\(.number):\(.baseRefName)"')

    if test -z "$prs"
        echo (set_color red)"No PRs found to merge for $branch."(set_color normal)
        return 1
    end

    for item in $prs
        set -l parts (string split ":" $item)
        set -l num $parts[1]
        set -l base $parts[2]

        if not set -q _flag_yes
            echo -n (set_color yellow)"Merge PR #$num into $base? [y/N] "(set_color normal)
            read -l confirm
            if test "$confirm" != "y" -a "$confirm" != "Y"
                continue
            end
        end

        # Merge using squash (standard for feature branches)
        gh pr merge "$num" --squash --delete-branch=false
        echo (set_color green)"Merged #$num into $base."(set_color normal)
    end
end
