function wt-clean --description "Clean worktrees (artifacts + merged branches)"

    function _wt_clean_usage
        echo "wt-clean - clean git worktrees"
        echo ""
        echo "Usage:"
        echo "  wt-clean [options]"
        echo ""
        echo "Cleanup options:"
        echo "  --all              Clean everything (node_modules, build, cache, logs)"
        echo "  --node             Remove node_modules"
        echo "  --build            Remove build outputs (dist, build, .next, etc.)"
        echo "  --cache            Remove caches (.turbo, .nx, etc.)"
        echo "  --logs             Remove logs/coverage"
        echo "  --deep             Include extra tool caches (vite, parcel, storybook)"
        echo ""
        echo "Merged worktree cleanup:"
        echo "  --merged           Remove worktrees with no unique commits (diff-based)"
        echo "  --base <branch>    Base branch to check against (default: develop)"
        echo "  --delete-branches  Also delete local branches"
        echo ""
        echo "Other:"
        echo "  --apply            Actually perform actions (default is dry-run)"
        echo "  --prune            Run 'git worktree prune'"
        echo "  -h, --help         Show this help"
    end

    # -------- Arg parsing --------
    argparse 'h/help' 'apply' 'all' 'node' 'build' 'cache' 'logs' 'prune' 'deep' \
             'merged' 'delete-branches' 'base=' -- $argv
    or return 1

    if set -q _flag_help
        _wt_clean_usage
        return 0
    end

    # -------- Logic Setup --------
    set -l APPLY (set -q _flag_apply; and echo 1; or echo 0)
    set -l BASE_BRANCH (set -q _flag_base; and echo $_flag_base; or echo "develop")
    set -l PROTECTED main develop staging master $BASE_BRANCH

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Error: Not inside a git repository."
        return 1
    end

    set -l root (pwd -P)

    # -------- Get worktrees --------
    set -l WT_PATHS
    set -l WT_BRANCHES
    for line in (git worktree list --porcelain)
        if string match -rq '^worktree ' -- $line
            set current_path (string replace -r '^worktree\s+' '' -- $line)
        else if string match -rq '^branch ' -- $line
            set -l ref (string replace -r '^branch\s+' '' -- $line)
            if string match -q 'refs/heads/*' -- $ref
                set -l br (string replace -r '^refs/heads/' '' -- $ref)
                set -l abs (realpath $current_path 2>/dev/null)
                if test -n "$abs"
                    set -a WT_PATHS $abs
                    set -a WT_BRANCHES $br
                end
            end
        end
    end

    # -------- Artifact cleanup (same as before) --------
    set -l targets
    set -q _flag_all; or set -q _flag_node; and set -a targets "node_modules"
    if set -q _flag_all; or set -q _flag_build
        set -a targets "dist" "build" "out" ".next"
        set -q _flag_deep; and set -a targets ".vite" ".parcel-cache" ".storybook-static"
    end
    if set -q _flag_all; or set -q _flag_cache
        set -a targets ".turbo" ".nx" ".eslintcache" "*.tsbuildinfo"
    end
    if set -q _flag_all; or set -q _flag_logs
        set -a targets "coverage" "*.log"
    end

    if test (count $targets) -gt 0
        test $APPLY -eq 0; and echo "-- DRY RUN: Artifacts --"
        for wt in $WT_PATHS
            for t in $targets
                for m in $wt/$t
                    if test -e "$m"
                        if test $APPLY -eq 1
                            rm -rf "$m"; echo "Deleted: $m"
                        else
                            echo "Would delete: $m"
                        end
                    end
                end
            end
        end
        echo ""
    end

    # -------- Merged cleanup (Diff-based) --------
    if set -q _flag_merged
        echo "Fetching updates from origin..."
        git fetch origin $BASE_BRANCH --quiet

        echo "Checking for branches with no unique commits relative to origin/$BASE_BRANCH..."

        for i in (seq (count $WT_PATHS))
            set -l wt $WT_PATHS[$i]
            set -l br $WT_BRANCHES[$i]

            if test "$wt" = "$root"; or contains -- $br $PROTECTED
                continue
            end

            # The logic: If 'git log BASE..BRANCH' is empty, BRANCH is fully contained in BASE
            set -l unique_commits (git log origin/$BASE_BRANCH..$br --oneline -n 1)

            if test -z "$unique_commits"
                if test $APPLY -eq 1
                    echo "Removing worktree: $wt ($br)"
                    git worktree remove --force "$wt"
                    if set -q _flag_delete_branches
                        # -D is needed because Git might still think it's unmerged due to hash mismatch
                        git branch -D "$br"
                    end
                else
                    echo "Would remove: $wt ($br)"
                end
            end
        end
        echo ""
    end

    if set -q _flag_prune
        if test $APPLY -eq 1
            git worktree prune; echo "Pruned worktree metadata."
        else
            echo "Would run: git worktree prune"
        end
    end
end
