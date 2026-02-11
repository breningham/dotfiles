function gen-pr-summary -d "Generates PR description via AI"
    argparse 'f/force' -- $argv

    set -l branch_name (git branch --show-current)
    set -l diff_content (git diff origin/main...HEAD)

    if test -z "$diff_content"
        echo (set_color red)"No changes detected against origin/main." >&2
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
        set template_instruction "Please format the response according to this template:\n$template\n remove any mentions of the template itself from the final output."
    end

    set -l ai_prompt "Analyze changes for '$branch_name'.
    Write a PR description in Markdown (Summary, Technical Changes, How to Test, Notes).
    $template_instruction
    Output ONLY markdown content."

    echo -n (set_color yellow)"... Generating via Gemini ... "(set_color normal) >&2
    set -l response (echo "$diff_content" | gemini -m "gemini-3-pro-preview" "$ai_prompt" 2>/dev/null | string collect)

    if test -n "$response"
        echo "$response" > "$cache_file"
        echo (set_color green)"Done!"(set_color normal) >&2
        echo "$response"
    else
        echo (set_color red)"Error: AI generation failed."(set_color normal) >&2
        return 1
    end
end
