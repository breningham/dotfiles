import { tool } from "@opencode-ai/plugin";
import {
  detectPackageManager,
  parseArgs,
  validateFlags,
} from "../utils/shell-parser";

export async function runPkg(command: string, rawArgs: string | string[] = []) {
  const ENV = { ...process.env, TERM: "dumb", CI: "true" };

  const argsArray = typeof rawArgs === "string" ? parseArgs(rawArgs) : rawArgs;

  const pkgManager = await detectPackageManager();
  const finalArgs = ["run", command, ...argsArray];

  const shell = Bun.$`${pkgManager} ${finalArgs}`
    .quiet()
    .throws(false)
    .env(ENV);

  console.log(`Executing: ${pkgManager} ${finalArgs.join(" ")}`);

  const pmProcess = await shell;
  const stdout = pmProcess.stdout.toString().trim();
  const stderr = pmProcess.stderr.toString().trim();

  // Combine output but prioritize stderr if exit code is non-zero
  return `Exit Code: ${pmProcess.exitCode}\nOutput:\n${stdout}\n${stderr}`.trim();
}

export const test = tool({
  description: "Run the project test suite or a specific test file.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("Path to a specific test file."),
    watch: tool.schema.boolean().default(false).describe("Run in watch mode."),
  },
  async execute({ path, watch }) {
    const args = ["test"];
    if (path) args.push(path);
    if (watch) args.push("--watch");
    return await runPkg("run", args);
  },
});

export const run = tool({
  description:
    "Execute a defined script from package.json (e.g., lint, build).",
  args: {
    script: tool.schema.string().describe("The name of the script to run."),
  },
  async execute({ script }) {
    return await runPkg("run", [script]);
  },
});
