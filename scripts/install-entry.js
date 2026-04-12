"use strict";

const path = require("path");
const { parseArgs } = require("./lib/common");
const { installSkill } = require("./install-skill");
const { checkInstall } = require("./check-install");

function buildOptionDefs() {
  return {
    "skill-repo-path": { name: "skillRepoPath", type: "string" },
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "backend-repo-path": { name: "backendRepoPath", type: "string" },
    "backend-package-spec": { name: "backendPackageSpec", type: "string" },
    "skip-smoke-test": { name: "skipSmokeTest", type: "boolean" },
    "check-only": { name: "checkOnly", type: "boolean" },
    "force-relink": { name: "forceRelink", type: "boolean" }
  };
}

function runInstallEntry(options = {}) {
  const repoRoot = path.resolve(options.skillRepoPath || path.join(__dirname, ".."));
  console.log(`Installing manage-current-session-habits from ${repoRoot}`);

  installSkill({
    skillRepoPath: repoRoot,
    codexSkillsRoot: options.codexSkillsRoot,
    backendRepoPath: options.backendRepoPath,
    backendPackageSpec: options.backendPackageSpec,
    checkOnly: options.checkOnly,
    forceRelink: options.forceRelink
  });

  if (options.checkOnly) {
    return;
  }

  if (options.skipSmokeTest) {
    console.log("Skipped smoke validation.");
    return;
  }

  console.log("Running install smoke validation...");
  const checks = checkInstall({
    skillRepoPath: repoRoot,
    codexSkillsRoot: options.codexSkillsRoot,
    smokeTest: true
  });

  for (const check of checks) {
    console.log(`[${check.status.toUpperCase()}] ${check.name} - ${check.detail}`);
  }
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  runInstallEntry(parsed.values);
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
  runInstallEntry
};
