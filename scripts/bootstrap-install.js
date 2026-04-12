"use strict";

const fs = require("fs");
const path = require("path");
const {
  convertToSshGitHubUrl,
  ensureDirectory,
  ensureGitClean,
  isGitRepository,
  normalizeRepositoryUrl,
  parseArgs,
  resolveCheckoutPath,
  runCommand
} = require("./lib/common");
const { runInstallEntry } = require("./install-entry");

const REPO_NAME = "manage-current-session-habits";

function buildOptionDefs() {
  return {
    "repository-url": { name: "repositoryUrl", type: "string" },
    "install-root": { name: "installRoot", type: "string" },
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "backend-repo-path": { name: "backendRepoPath", type: "string" },
    "backend-package-spec": { name: "backendPackageSpec", type: "string" },
    "skip-smoke-test": { name: "skipSmokeTest", type: "boolean" },
    "check-only": { name: "checkOnly", type: "boolean" },
    "force-relink": { name: "forceRelink", type: "boolean" }
  };
}

function ensureRepositoryCheckout(targetPath, repositoryUrl) {
  if (!fs.existsSync(targetPath)) {
    ensureDirectory(path.dirname(targetPath));
    try {
      runCommand("git", ["clone", repositoryUrl, targetPath], { captureOutput: false });
      return "cloned";
    } catch (error) {
      const sshUrl = convertToSshGitHubUrl(repositoryUrl);
      if (!sshUrl) {
        throw error;
      }

      console.log("HTTPS clone failed. Retrying with SSH...");
      runCommand("git", ["clone", sshUrl, targetPath], { captureOutput: false });
      return "cloned via ssh fallback";
    }
  }

  if (!isGitRepository(targetPath)) {
    throw new Error(`Install root already exists but is not a git repository: ${targetPath}`);
  }

  ensureGitClean(targetPath);
  const originUrl = runCommand("git", ["-C", targetPath, "remote", "get-url", "origin"]).stdout.trim();
  if (normalizeRepositoryUrl(originUrl) !== normalizeRepositoryUrl(repositoryUrl)) {
    throw new Error(`Install root points to a different origin: ${originUrl}`);
  }

  runCommand("git", ["-C", targetPath, "pull", "--ff-only", "origin", "main"], {
    captureOutput: false
  });
  return "updated";
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  const options = parsed.values;
  const repositoryUrl = options.repositoryUrl || "https://github.com/pingzi-crypto/manage-current-session-habits.git";
  const resolvedInstallRoot = resolveCheckoutPath(options.installRoot, REPO_NAME);
  const checkoutAction = ensureRepositoryCheckout(resolvedInstallRoot, repositoryUrl);
  console.log(`Repository ${checkoutAction}: ${resolvedInstallRoot}`);

  runInstallEntry({
    skillRepoPath: resolvedInstallRoot,
    codexSkillsRoot: options.codexSkillsRoot,
    backendRepoPath: options.backendRepoPath,
    backendPackageSpec: options.backendPackageSpec,
    skipSmokeTest: options.skipSmokeTest,
    checkOnly: options.checkOnly,
    forceRelink: options.forceRelink
  });
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
