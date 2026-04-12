"use strict";

const fs = require("fs");
const path = require("path");
const { parseArgs, readJsonFile, runCommand } = require("./lib/common");

function buildOptionDefs() {
  return {
    request: { name: "request", type: "string" },
    thread: { name: "threadPath", type: "string" },
    "thread-path": { name: "threadPath", type: "string" },
    transcript: { name: "transcript", type: "string" },
    "thread-stdin": { name: "threadStdin", type: "boolean" },
    "user-registry": { name: "userRegistryPath", type: "string" },
    "user-registry-path": { name: "userRegistryPath", type: "string" },
    "max-candidates": { name: "maxCandidates", type: "string" },
    "config-path": { name: "configPath", type: "string" }
  };
}

function invokeBackend(options = {}) {
  if (!options.request) {
    throw new Error("--request is required.");
  }

  const threadSourceCount = [options.threadPath, options.transcript, options.threadStdin].filter(Boolean).length;
  if (threadSourceCount > 1) {
    throw new Error("Use only one thread source: --thread-path, --transcript, or --thread-stdin.");
  }

  const configPath = path.resolve(
    options.configPath || path.join(__dirname, "..", "config", "local-config.json")
  );
  if (!fs.existsSync(configPath)) {
    throw new Error(`Missing local config at ${configPath}. Run install first.`);
  }

  const config = readJsonFile(configPath);
  const bridgeCliPath = config.bridge_cli_path;
  if (!bridgeCliPath) {
    throw new Error("local-config.json must include bridge_cli_path.");
  }

  const resolvedBridgeCliPath = path.resolve(bridgeCliPath);
  if (!fs.existsSync(resolvedBridgeCliPath)) {
    throw new Error(`Configured bridge CLI was not found at ${resolvedBridgeCliPath}.`);
  }

  const commandArgs = ["--request", options.request];
  let input;

  if (options.threadStdin) {
    commandArgs.push("--thread-stdin");
    input = fs.readFileSync(0, "utf8");
    if (!input.trim()) {
      throw new Error("--thread-stdin requires non-empty stdin input.");
    }
  }

  if (options.threadPath) {
    commandArgs.push("--thread", options.threadPath);
  }

  if (options.transcript !== undefined) {
    if (!String(options.transcript).trim()) {
      throw new Error("--transcript requires non-empty text.");
    }
    commandArgs.push("--thread-stdin");
    input = options.transcript;
  }

  if (options.userRegistryPath) {
    commandArgs.push("--user-registry", options.userRegistryPath);
  }

  if (options.maxCandidates !== undefined) {
    commandArgs.push("--max-candidates", String(options.maxCandidates));
  }

  const isJsBridge = path.extname(resolvedBridgeCliPath).toLowerCase() === ".js";
  const command = isJsBridge ? process.execPath : resolvedBridgeCliPath;
  const args = isJsBridge ? [resolvedBridgeCliPath, ...commandArgs] : commandArgs;
  const result = runCommand(command, args, { input });
  return result.stdout;
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  const output = invokeBackend(parsed.values);
  process.stdout.write(output);
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

module.exports = {
  invokeBackend
};
