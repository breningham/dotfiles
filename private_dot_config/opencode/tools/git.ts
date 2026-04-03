import { tool, Plugin } from "@opencode-ai/plugin";

export async function runGit(subcommand: string, args: string[] = []) {
  const ENV = {
    ...process.env,
    TERM: "dumb",
  };
  const globalFlags = ["--no-pager", "-c", "color.ui=false"];

  // .throws(false) prevents Bun from automatically throwing on exit code 1
  // .quiet() is essential to stop it leaking into your CLI
  const shell = Bun.$`git ${globalFlags} ${subcommand} ${args}`
    .quiet()
    .throws(false)
    .env(ENV);

  console.log(
    `Running command: git ${globalFlags.join(" ")} ${subcommand} ${args.join(" ")}`,
  );

  const gitProcess = await shell;

  const stdout = gitProcess.stdout.toString().trim();
  const stderr = gitProcess.stderr.toString().trim();
  const output = (stdout + "\n" + stderr).trim();

  if (gitProcess.exitCode !== 0 && !output) {
    throw new Error(
      `Git ${subcommand} failed with code ${gitProcess.exitCode}`,
    );
  }

  return output.replace(/\t/g, "  ");
}

export const branch = tool({
  description: "List, create, or delete branches.",
  args: {
    all: tool.schema
      .boolean()
      .default(true)
      .describe("List both remote-tracking branches and local branches."),
    remotes: tool.schema
      .boolean()
      .default(false)
      .describe("List only the remote-tracking branches."),
  },
  async execute({ all, remotes }) {
    const args = [];

    if (remotes) {
      args.push("-r");
    } else if (all) {
      args.push("-a");
    }

    // --vv provides upstream branch info and the latest commit subject
    args.push("-vv");

    return await runGit("branch", args);
  },
});

export const diff = tool({
  description: "View changes between branches, commits, or the working tree.",
  args: {
    target: tool.schema
      .string()
      .optional()
      .describe(
        "The branch or commit to compare against (e.g., 'main' or 'origin/master').",
      ),
    source: tool.schema
      .string()
      .optional()
      .describe(
        "The starting point for comparison. If omitted, uses the current working tree.",
      ),
    staged: tool.schema
      .boolean()
      .optional()
      .describe(
        "View changes staged for the next commit (only valid if source/target are omitted).",
      ),
    path: tool.schema
      .string()
      .optional()
      .describe("Limit diff to a specific file or directory."),
    stat: tool.schema
      .boolean()
      .default(true)
      .describe("Show only a summary of changed files (diffstat)."),
  },
  async execute({ target, source, staged, path, stat }) {
    const args = [];

    if (source && target) {
      // Diffs two specific points: git diff main..feature-branch
      args.push(`${source}..${target}`);
    } else if (target) {
      // Diffs current branch against target: git diff main
      args.push(target);
    } else if (staged) {
      args.push("--staged");
    }

    if (stat) {
      args.push("--stat");
    }

    if (path) {
      // The '--' separator ensures git treats the string as a path, not a branch name
      args.push("--", path);
    }

    return await runGit("diff", args);
  },
});

export const status = tool({
  description: "Show the working tree status.",
  args: {}, // No args needed for a basic status
  async execute() {
    return await runGit("status", ["--short"]);
  },
});

export const log = tool({
  description: "View the commit history of the repository.",
  args: {
    limit: tool.schema
      .number()
      .default(10)
      .describe("The maximum number of commits to return. Defaults to 10."),
    author: tool.schema
      .string()
      .optional()
      .describe("Filter logs by a specific author name or email."),
    oneline: tool.schema
      .boolean()
      .default(true)
      .describe("Return a condensed one-line-per-commit format."),
  },
  async execute({ limit, author, oneline }) {
    const args = [`-n`, limit.toString()];

    if (oneline) {
      // --format creates a clean, predictable string for the LLM
      args.push("--format=%h %as | %s (%an)");
    }

    if (author) {
      args.push(`--author=${author}`);
    }

    return await runGit("log", args);
  },
});

export const show = tool({
  description:
    "View the changes and commit message for a specific commit hash.",
  args: {
    commitHash: tool.schema
      .string()
      .describe("The SHA-1 hash of the commit (e.g., 'a1b2c3d')."),
    showStat: tool.schema
      .boolean()
      .default(false)
      .describe(
        "Show only a summary of changed files (diffstat) instead of the full diff.",
      ),
  },
  async execute({ commitHash, showStat }) {
    const args = [commitHash];

    if (showStat) {
      args.push("--stat");
    } else {
      // Patch format is the most readable for LLMs to understand code changes
      args.push("--patch");
    }

    return await runGit("show", args);
  },
});
