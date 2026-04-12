"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { parseArgs, removePath } = require("./lib/common");
const { runInstallEntry } = require("./install-entry");
const { uninstallSkill } = require("./uninstall-skill");

function buildOptionDefs() {
  return {
    "skill-repo-path": { name: "skillRepoPath", type: "string" },
    "backend-repo-path": { name: "backendRepoPath", type: "string" },
    "codex-home": { name: "codexHome", type: "string" },
    "skip-repo-mode": { name: "skipRepoMode", type: "boolean" }
  };
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  const options = parsed.values;
  const skillRepoPath = path.resolve(options.skillRepoPath || path.join(__dirname, ".."));
  const codexHome = path.resolve(
    options.codexHome || fs.mkdtempSync(path.join(os.tmpdir(), "manage-current-session-habits-ci-"))
  );
  const previousCodexHome = process.env.CODEX_HOME;
  process.env.CODEX_HOME = codexHome;

  const steps = [];
  const codexSkillsRoot = path.join(codexHome, "skills");
  const addStep = (detail) => {
    steps.push(detail);
    console.log(detail);
  };

  try {
    addStep("package-mode install + smoke");
    runInstallEntry({
      codexSkillsRoot,
      forceRelink: true
    });

    addStep("package-mode refresh + smoke");
    runInstallEntry({
      codexSkillsRoot,
      forceRelink: true
    });

    addStep("package-mode uninstall");
    uninstallSkill({ codexSkillsRoot });

    if (!options.skipRepoMode) {
      if (!options.backendRepoPath) {
        throw new Error("Repo-mode smoke requires --backend-repo-path unless --skip-repo-mode is set.");
      }

      addStep("repo-mode install + smoke");
      runInstallEntry({
        codexSkillsRoot,
        backendRepoPath: path.resolve(options.backendRepoPath),
        forceRelink: true
      });

      addStep("repo-mode uninstall");
      uninstallSkill({ codexSkillsRoot });
    }

    console.log(
      JSON.stringify(
        {
          ok: true,
          skill_repo: skillRepoPath,
          codex_home: codexHome,
          repo_mode: !options.skipRepoMode,
          steps
        },
        null,
        2
      )
    );
  } finally {
    if (previousCodexHome) {
      process.env.CODEX_HOME = previousCodexHome;
    } else {
      delete process.env.CODEX_HOME;
    }

    if (fs.existsSync(codexHome)) {
      removePath(codexHome);
    }
  }
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
