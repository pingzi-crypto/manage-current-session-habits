"use strict";

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

function parseArgs(argv, optionDefs = {}) {
  const values = {};
  const positionals = [];

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("-")) {
      positionals.push(token);
      continue;
    }

    const stripped = token.replace(/^-+/, "");
    const definition = optionDefs[stripped];
    if (!definition) {
      throw new Error(`Unknown option: ${token}`);
    }

    if (definition.type === "boolean") {
      values[definition.name] = true;
      continue;
    }

    index += 1;
    if (index >= argv.length) {
      throw new Error(`Option ${token} requires a value.`);
    }
    values[definition.name] = argv[index];
  }

  return { values, positionals };
}

function ensureDirectory(targetPath) {
  fs.mkdirSync(targetPath, { recursive: true });
}

function writeUtf8File(targetPath, content) {
  fs.writeFileSync(targetPath, `${content}\n`, "utf8");
}

function writeJsonFile(targetPath, value) {
  writeUtf8File(targetPath, JSON.stringify(value, null, 2));
}

function readJsonFile(targetPath) {
  return JSON.parse(fs.readFileSync(targetPath, "utf8"));
}

function getHomeDirectory() {
  if (process.env.HOME) {
    return process.env.HOME;
  }

  if (process.env.USERPROFILE) {
    return process.env.USERPROFILE;
  }

  throw new Error("Unable to determine the user home directory. Set HOME, USERPROFILE, or CODEX_HOME.");
}

function getDefaultCodexSkillsRoot() {
  if (process.env.CODEX_HOME) {
    return path.join(process.env.CODEX_HOME, "skills");
  }

  return path.join(getHomeDirectory(), ".codex", "skills");
}

function resolveBackendRepoPath(providedPath) {
  if (providedPath) {
    return path.resolve(providedPath);
  }

  if (process.env.USER_HABIT_PIPELINE_REPO) {
    return path.resolve(process.env.USER_HABIT_PIPELINE_REPO);
  }

  return null;
}

function realpathSafe(targetPath) {
  try {
    return fs.realpathSync.native(targetPath);
  } catch {
    return null;
  }
}

function lstatSafe(targetPath) {
  try {
    return fs.lstatSync(targetPath);
  } catch {
    return null;
  }
}

function pathForCompare(targetPath) {
  const normalized = path.resolve(targetPath);
  if (process.platform === "win32") {
    return normalized.toLowerCase();
  }

  return normalized;
}

function pathsEqual(left, right) {
  return pathForCompare(left) === pathForCompare(right);
}

function pointsToPath(linkPath, expectedTargetPath) {
  const resolvedLink = realpathSafe(linkPath);
  if (!resolvedLink) {
    return false;
  }

  const resolvedExpected = realpathSafe(expectedTargetPath) || path.resolve(expectedTargetPath);
  return pathsEqual(resolvedLink, resolvedExpected);
}

function createDirectoryLink(linkPath, targetPath) {
  const linkType = process.platform === "win32" ? "junction" : "dir";
  fs.symlinkSync(targetPath, linkPath, linkType);
  return process.platform === "win32" ? "Junction" : "SymbolicLink";
}

function removePath(targetPath) {
  fs.rmSync(targetPath, { recursive: true, force: true });
}

function getCommandPath(command) {
  if (path.isAbsolute(command)) {
    return command;
  }

  if (process.platform === "win32" && !path.extname(command) && command === "npm") {
    return "npm.cmd";
  }

  return command;
}

function runCommand(command, args, options = {}) {
  const executable = getCommandPath(command);
  const useWindowsShell = process.platform === "win32" && /\.(cmd|bat)$/iu.test(executable);
  const result = spawnSync(executable, args, {
    cwd: options.cwd,
    env: options.env,
    input: options.input,
    encoding: "utf8",
    shell: useWindowsShell,
    stdio: options.captureOutput === false ? "inherit" : "pipe"
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    const stderr = result.stderr ? result.stderr.trim() : "";
    const stdout = result.stdout ? result.stdout.trim() : "";
    const detail = [stderr, stdout].filter(Boolean).join("\n");
    throw new Error(detail || `${command} exited with status ${result.status}`);
  }

  return result;
}

function ensureGitClean(repoPath) {
  const status = runCommand("git", ["-C", repoPath, "status", "--porcelain"]);
  if (status.stdout.trim()) {
    throw new Error(`Install root contains local changes: ${repoPath}. Commit or clean them before bootstrap update.`);
  }
}

function normalizeRepositoryUrl(url) {
  const httpsMatch = /^https:\/\/github\.com\/([^/]+)\/([^/]+?)(?:\.git)?\/?$/iu.exec(url);
  if (httpsMatch) {
    return `github.com/${httpsMatch[1]}/${httpsMatch[2]}`.toLowerCase();
  }

  const sshMatch = /^git@github\.com:([^/]+)\/([^/]+?)(?:\.git)?$/iu.exec(url);
  if (sshMatch) {
    return `github.com/${sshMatch[1]}/${sshMatch[2]}`.toLowerCase();
  }

  return path.resolve(url).toLowerCase();
}

function convertToSshGitHubUrl(url) {
  const httpsMatch = /^https:\/\/github\.com\/([^/]+)\/([^/]+?)(?:\.git)?\/?$/iu.exec(url);
  if (!httpsMatch) {
    return null;
  }

  return `git@github.com:${httpsMatch[1]}/${httpsMatch[2]}.git`;
}

function resolveCheckoutPath(providedPath, repoName) {
  if (!providedPath) {
    const codexRoot = process.env.CODEX_HOME || path.join(getHomeDirectory(), ".codex");
    return path.join(codexRoot, "repos", repoName);
  }

  const resolvedCandidate = path.resolve(providedPath);
  if (path.basename(resolvedCandidate) === repoName) {
    return resolvedCandidate;
  }

  return path.join(resolvedCandidate, repoName);
}

function isGitRepository(targetPath) {
  return fs.existsSync(path.join(targetPath, ".git"));
}

function readInstalledPackageVersion(installRoot, packageName) {
  const packageJsonPath = path.join(installRoot, "node_modules", packageName, "package.json");
  if (!fs.existsSync(packageJsonPath)) {
    return null;
  }

  return readJsonFile(packageJsonPath).version || null;
}

module.exports = {
  convertToSshGitHubUrl,
  createDirectoryLink,
  ensureDirectory,
  ensureGitClean,
  getDefaultCodexSkillsRoot,
  isGitRepository,
  lstatSafe,
  normalizeRepositoryUrl,
  parseArgs,
  pathsEqual,
  pointsToPath,
  readInstalledPackageVersion,
  readJsonFile,
  realpathSafe,
  removePath,
  resolveBackendRepoPath,
  resolveCheckoutPath,
  runCommand,
  writeJsonFile
};
