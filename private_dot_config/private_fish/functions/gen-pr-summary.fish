function gen-pr-summary -d "Generate PR description via AI (multi-sample + best-of selection)"
    argparse 'f/force' 'd/debug' 'm/model=' 'n/num=' -- $argv

    set -l model "openrouter/openrouter/free"
    if set -q _flag_model
        set model $_flag_model
    end

    # number of candidates (default 3, min 2, max 3)
    set -l num 3
    if set -q _flag_num
        set num $_flag_num
    end

    if test $num -lt 2
        set num 2
    end
    if test $num -gt 3
        set num 3
    end

    set -l branch_name (git branch --show-current)
    or begin
        echo "Failed to get branch" >&2
        return 1
    end

    set -l base "origin/main"

    set -l diff_stat (git diff --stat $base...HEAD)
    set -l changed_files (git diff --name-only $base...HEAD)
    set -l diff_content (git diff $base...HEAD | head -c 150000)

    if test -z "$diff_content"
        echo (set_color red)"No changes detected against $base."(set_color normal) >&2
        return 1
    end

    set -l current_head (git rev-parse --short HEAD)
    set -l safe_branch (string replace -a "/" "-" -- $branch_name)
    set -l cache_file "/tmp/pr-desc-$safe_branch-$current_head.md"

    if set -q _flag_force; and test -f "$cache_file"
        rm "$cache_file"
    end

    if test -f "$cache_file"
        cat "$cache_file"
        return 0
    end

    set -l template_instruction ""
    if test -f ".github/pull_request_template.md"
        set -l template (cat .github/pull_request_template.md)
        set template_instruction "Follow this PR template strictly:\n$template\nDo not mention the template in your output."
    end

    set -l ai_prompt "You are generating a Pull Request description.\n\nSummarise the INTENT of the change, not the raw code.\n\nRules:\n- Be concise and specific\n- No generic phrases like 'this improves' or 'this updates'\n- Do not repeat the diff\n- Do not explain obvious changes\n\nOutput format (strict):\n\n## Summary\n- 2–4 bullet points describing what changed and why\n\n## Technical Changes\n- Group related changes\n- Use short, concrete bullets\n\n## How to Test\n- Provide clear, actionable steps\n- If no testing needed, say: 'No runtime testing required'\n\n## Notes\n- Only include if relevant\n\nContext:\n\nChanged files:\n$changed_files\n\nDiff summary:\n$diff_stat\n\nKey excerpts:\n$diff_content\n\n$template_instruction\n\nTemplate:\n -If exists use `.github/pull_request_template.md`\n\nOutput ONLY markdown."

    if set -q _flag_debug
        echo "--- PROMPT ---" >&2
        echo "$ai_prompt" >&2
    end

    echo -n (set_color yellow)"... Generating $num candidates via $model ... "(set_color normal) >&2

    set -l candidates
    set -l scores

    for i in (seq 1 $num)
        set -l tmp_err (mktemp)

        set -l response (_ai_generate "$model" "$ai_prompt" 2> $tmp_err | string collect)
        set -l cmd_status $status

        if test $cmd_status -ne 0; or test -z "$response"
            if set -q _flag_debug
                echo "Candidate $i failed:" >&2
                cat $tmp_err >&2
            end
            rm $tmp_err
            continue
        end

        rm $tmp_err

        # score the response (simple heuristic)
        set -l score 0

        string match -q "*## Summary*" "$response"; and set score (math "$score + 2")
        string match -q "*## Technical Changes*" "$response"; and set score (math "$score + 2")
        string match -q "*## How to Test*" "$response"; and set score (math "$score + 2")

        # penalise overly short outputs
        set -l len (string length "$response")
        if test $len -gt 300
            set score (math "$score + 1")
        end

        # penalise generic phrases
        if string match -q "*this improves*" "$response"
            set score (math "$score - 1")
        end

        set candidates $candidates "$response"
        set scores $scores $score
    end

    if test (count $candidates) -eq 0
        echo (set_color red)"Error: all AI generations failed."(set_color normal) >&2
        return 1
    end

    # pick best candidate
    set -l best_idx 1
    set -l best_score $scores[1]

    for i in (seq 1 (count $scores))
        if test $scores[$i] -gt $best_score
            set best_score $scores[$i]
            set best_idx $i
        end
    end

    set -l best "$candidates[$best_idx]"

    if set -q _flag_debug
        echo "--- SCORES ---" >&2
        for i in (seq 1 (count $scores))
            echo "Candidate $i: $scores[$i]" >&2
        end
        echo "Selected: $best_idx" >&2
    end

    echo "$best" > "$cache_file"

    echo (set_color green)"Done! (selected best of $num)"(set_color normal) >&2
    echo "$best"
end


function _ai_generate
    set -l model (string trim -- $argv[1])
    set -l prompt (string trim -- $argv[2])

    opencode run \
        --model "$model" \
        "$prompt"
end
