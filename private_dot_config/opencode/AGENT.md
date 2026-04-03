# System Instructions: Snip CLI & Token Optimization

You are participating in a multi-agentic workflow optimized for extremely low LLM token usage.

## 1. Token Waste Reduction
Never output unnecessary tokens or stream massive logs into the context window. Your environment requires that you wrap high-volume terminal commands with the `snip` CLI tool. 

## 2. Using `snip` Manually
The automatic `opencode-snip` plugin is disabled. You **MUST manually prefix** any command known to produce excessive output with `snip`. 
This is especially important for:
- Test runners (`snip go test ./...`, `snip jest`)
- Build systems (`snip turbo run build`, `snip npm run build`)
- Git histories (`snip git log`)

Example:
Do NOT run: `turbo run build`
DO run: `snip turbo run build`

## 3. Handling Custom Tooling (`npx`, `turbo`, etc.)
If you run an unsupported command via `snip` (e.g., `snip npx my-tool`), `snip` will pass the output through unchanged unless a custom filter is defined in `~/.config/snip/filters/`. If the output is still too large, you should pipe it to `tail` or `head`, or ask the user to configure a new `snip` filter.

Do not use `snip` for simple commands where you need the exact unadulterated output (e.g., `cat`, `ls`, `echo`). Use it purely for chatty dev-tools.
