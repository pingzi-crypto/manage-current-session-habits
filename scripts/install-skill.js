"use strict";

const fs = require("fs");
const path = require("path");
const {
  createDirectoryLink,
  ensureDirectory,
  getDefaultCodexSkillsRoot,
  lstatSafe,
  parseArgs,
  pointsToPath,
  readInstalledPackageVersion,
  resolveBackendRepoPath,
  removePath,
  runCommand,
  writeJsonFile
} = require("./lib/common");

function buildOptionDefs() {
  return {
    "skill-repo-path": { name: "skillRepoPath", type: "string" },
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "backend-repo-path": { name: "backendRepoPath", type: "string" },
    "backend-package-spec": { name: "backendPackageSpec", type: "string" },
    "check-only": { name: "checkOnly", type: "boolean" },
    "force-relink": { name: "forceRelink", type: "boolean" }
  };
}

function installBackendPackage(installRoot, packageSpec) {
  ensureDirectory(installRoot);
  const packageJsonPath = path.join(installRoot, "package.json");
  if (!fs.existsSync(packageJsonPath)) {
    writeJsonFile(packageJsonPath, {
      name: "manage-current-session-habits-backend-runtime",
      private: true
    });
  }

  runCommand("npm", ["install", "--prefix", installRoot, packageSpec], {
    captureOutput: false
  });

  const packageVersion = readInstalledPackageVersion(installRoot, "user-habit-pipeline");
  if (!packageVersion) {
    throw new Error(`Installed backend package metadata was not found under ${installRoot}`);
  }

  return packageVersion;
}

function installSkill(options = {}) {
  const resolvedRepoPath = path.resolve(options.skillRepoPath || path.join(__dirname, ".."));
  const resolvedBackendRepoPath = resolveBackendRepoPath(options.backendRepoPath);
  const codexSkillsRoot = path.resolve(options.codexSkillsRoot || getDefaultCodexSkillsRoot());
  const backendPackageSpec = options.backendPackageSpec || "user-habit-pipeline@latest";
  const skillName = path.basename(resolvedRepoPath);
  const targetPath = path.join(codexSkillsRoot, skillName);
  const configDir = path.join(resolvedRepoPath, "config");
  const configPath = path.join(configDir, "local-config.json");
  const backendInstallRoot = path.join(configDir, "npm-backend");

  let configObject;
  let bridgeCliPath;

  if (resolvedBackendRepoPath) {
    bridgeCliPath = path.join(resolvedBackendRepoPath, "src", "codex-session-habits-cli.js");
    if (!fs.existsSync(bridgeCliPath)) {
      throw new Error(`Bridge CLI was not found at ${bridgeCliPath}`);
    }

    configObject = {
      backend_source: "repo",
      backend_repo_path: resolvedBackendRepoPath,
      bridge_cli_path: bridgeCliPath
    };
  } else if (options.checkOnly) {
    bridgeCliPath = path.join(
      backendInstallRoot,
      "node_modules",
      ".bin",
      process.platform === "win32" ? "codex-session-habits.cmd" : "codex-session-habits"
    );
    configObject = {
      backend_source: "package",
      backend_package_name: "user-habit-pipeline",
      backend_package_spec: backendPackageSpec,
      backend_install_root: backendInstallRoot,
      bridge_cli_path: bridgeCliPath
    };
  } else {
    const installedVersion = installBackendPackage(backendInstallRoot, backendPackageSpec);
    bridgeCliPath = path.join(
      backendInstallRoot,
      "node_modules",
      ".bin",
      process.platform === "win32" ? "codex-session-habits.cmd" : "codex-session-habits"
    );
    if (!fs.existsSync(bridgeCliPath)) {
      throw new Error(`Installed backend bridge CLI was not found at ${bridgeCliPath}`);
    }

    configObject = {
      backend_source: "package",
      backend_package_name: "user-habit-pipeline",
      backend_package_version: installedVersion,
      backend_install_root: backendInstallRoot,
      bridge_cli_path: bridgeCliPath
    };
  }

  const existing = lstatSafe(targetPath);
  const alreadyPointsToRepo = existing ? pointsToPath(targetPath, resolvedRepoPath) : false;

  if (options.checkOnly) {
    console.log("Check-only mode: no files will be modified.");
    console.log(`Skill repo: ${resolvedRepoPath}`);
    console.log(`Codex skills root: ${codexSkillsRoot}`);
    console.log(`Install target: ${targetPath}`);
    console.log(`Config path: ${configPath}`);
    if (configObject.backend_source === "repo") {
      console.log("Backend source: repo");
      console.log(`Backend repo: ${resolvedBackendRepoPath}`);
    } else {
      console.log("Backend source: npm package");
      console.log(`Backend package spec: ${backendPackageSpec}`);
      console.log(`Backend install root: ${backendInstallRoot}`);
    }
    console.log(`Bridge CLI: ${bridgeCliPath}`);

    if (!existing) {
      console.log("Install target does not exist yet.");
    } else if (alreadyPointsToRepo) {
      console.log("Existing install target already points to this repository.");
    } else {
      console.log("Existing install target exists and would be replaced.");
    }

    return;
  }

  ensureDirectory(configDir);
  writeJsonFile(configPath, configObject);
  ensureDirectory(codexSkillsRoot);

  if (existing && alreadyPointsToRepo && !options.forceRelink) {
    console.log(`Wrote local config: ${configPath}`);
    console.log(`Skill link already points to ${resolvedRepoPath}`);
    return;
  }

  if (existing) {
    removePath(targetPath);
  }

  const linkType = createDirectoryLink(targetPath, resolvedRepoPath);
  const verb = existing && alreadyPointsToRepo && options.forceRelink ? "Recreated" : "Installed";
  console.log(`${verb} skill link (${linkType}): ${targetPath} -> ${resolvedRepoPath}`);
  console.log(`Wrote local config: ${configPath}`);
  if (configObject.backend_source === "repo") {
    console.log(`Using backend repo: ${resolvedBackendRepoPath}`);
  } else if (configObject.backend_package_version) {
    console.log(`Using backend package: ${configObject.backend_package_name}@${configObject.backend_package_version}`);
  } else {
    console.log(`Using backend package spec: ${backendPackageSpec}`);
  }
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  installSkill(parsed.values);
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
  installSkill
};
