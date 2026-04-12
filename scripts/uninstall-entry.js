"use strict";

const { parseArgs } = require("./lib/common");
const { uninstallSkill } = require("./uninstall-skill");

function buildOptionDefs() {
  return {
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "keep-generated-backend": { name: "keepGeneratedBackend", type: "boolean" },
    "check-only": { name: "checkOnly", type: "boolean" }
  };
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
