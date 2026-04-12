"use strict";

const fs = require("fs");
const path = require("path");
const {
  getDefaultCodexSkillsRoot,
  parseArgs,
  pointsToPath,
  removePath
} = require("./lib/common");

function buildOptionDefs() {
  return {
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "keep-generated-backend": { name: "keepGeneratedBackend", type: "boolean" },
    "check-only": { name: "checkOnly", type: "boolean" }
  };
}

function uninstallSkill(options = {}) {
  const codexSkillsRoot = path.resolve(options.codexSkillsRoot || getDefaultCodexSkillsRoot());
  const repoRoot = path.resolve(path.join(__dirname, ".."));
  const skillName = path.basename(repoRoot);
  const installedSkillPath = path.join(codexSkillsRoot, skillName);
  const configPath = path.join(repoRoot, "config", "local-config.json");
  const backendInstallRoot = path.join(repoRoot, "config", "npm-backend");
  const actions = [];

  if (fs.existsSync(installedSkillPath) && pointsToPath(installedSkillPath, repoRoot)) {
    actions.push(`remove skill link: ${installedSkillPath}`);
  }

  if (fs.existsSync(configPath)) {
    actions.push(`remove generated config: ${configPath}`);
  }

  if (!options.keepGeneratedBackend && fs.existsSync(backendInstallRoot)) {
    actions.push(`remove generated backend runtime: ${backendInstallRoot}`);
  }

  if (actions.length === 0) {
    console.log("Nothing to remove.");
    return;
  }

  if (options.checkOnly) {
    console.log("Check-only mode: no files will be modified.");
    for (const action of actions) {
      console.log(action);
    }
    return;
  }

  for (const action of actions) {
    console.log(action);
  }

  if (fs.existsSync(installedSkillPath) && pointsToPath(installedSkillPath, repoRoot)) {
    removePath(installedSkillPath);
  }
  if (fs.existsSync(configPath)) {
    removePath(configPath);
  }
  if (!options.keepGeneratedBackend && fs.existsSync(backendInstallRoot)) {
    removePath(backendInstallRoot);
  }

  console.log("Uninstall complete.");
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  uninstallSkill(parsed.values);
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
  uninstallSkill
};
