/**
 * Splits a string into an array of arguments,
 * respecting single and double quotes.
 */
export function parseArgs(input: string): string[] {
  const args: string[] = [];
  const regex = /[^\s"']+|"([^"]*)"|'([^']*)'/g;
  let match;

  while ((match = regex.exec(input)) !== null) {
    // Index 1 is double-quoted group, Index 2 is single-quoted, Index 0 is unquoted
    args.push(match[1] || match[2] || match[0]);
  }
  return args;
}

/**
 * Prevents "Argument Injection" by blocking dangerous flags
 * that LLMs might try to slip in.
 */
export function validateFlags(args: string[]): void {
  const forbidden = ["--exec", "--config", "--eval", "-e"];
  for (const arg of args) {
    if (forbidden.some((f) => arg.startsWith(f))) {
      throw new Error(`Security Violation: Forbidden flag detected: ${arg}`);
    }
  }
}

export async function detectPackageManager(): Promise<"pnpm" | "npm" | "yarn"> {
  if (await Bun.file("package-lock.json").exists()) {
    return "npm";
  }

  if (await Bun.file("pnpm-lock.yaml").exists()) {
    return "pnpm";
  }

  if (await Bun.file("yarn.yaml").exists()) {
    return "yarn";
  }

  console.warn("unable to determine package manager, defaulting to npm");
  return "npm";
}
