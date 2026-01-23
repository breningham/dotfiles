function gwp --description 'Prune stale git worktree entries'
    git worktree prune
    echo "🧹 Pruned stale worktrees."
    git worktree list
end
