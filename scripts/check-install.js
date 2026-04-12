"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const {
  getDefaultCodexSkillsRoot,
  lstatSafe,
  parseArgs,
  pointsToPath,
  readJsonFile,
  removePath
} = require("./lib/common");
const { invokeBackend } = require("./invoke-backend");

function buildOptionDefs() {
  return {
    "skill-repo-path": { name: "skillRepoPath", type: "string" },
    "codex-skills-root": { name: "codexSkillsRoot", type: "string" },
    "config-path": { name: "configPath", type: "string" },
    "smoke-test": { name: "smokeTest", type: "boolean" }
  };
}

function addCheck(checks, name, status, detail) {
  checks.push({ name, status, detail });
}

function checkInstall(options = {}) {
  const resolvedRepoPath = path.resolve(options.skillRepoPath || path.join(__dirname, ".."));
  const codexSkillsRoot = path.resolve(options.codexSkillsRoot || getDefaultCodexSkillsRoot());
  const skillName = path.basename(resolvedRepoPath);
  const installedSkillPath = path.join(codexSkillsRoot, skillName);
  const configPath = path.resolve(options.configPath || path.join(resolvedRepoPath, "config", "local-config.json"));
  const checks = [];

  addCheck(checks, "skill_repo", "ok", resolvedRepoPath);

  if (!fs.existsSync(installedSkillPath)) {
    throw new Error(`Installed skill entry was not found at ${installedSkillPath}`);
  }

  const installedStat = lstatSafe(installedSkillPath);
  const installedPointsToRepo = pointsToPath(installedSkillPath, resolvedRepoPath);
  if (!installedStat || !installedStat.isSymbolicLink()) {
    addCheck(checks, "skill_link", "warn", `Installed path exists but is not a link: ${installedSkillPath}`);
  } else if (!installedPointsToRepo) {
    addCheck(checks, "skill_link", "warn", `Installed skill points elsewhere: ${installedSkillPath}`);
  } else {
    addCheck(checks, "skill_link", "ok", `${installedSkillPath} -> ${resolvedRepoPath}`);
  }

  if (!fs.existsSync(configPath)) {
    throw new Error(`Missing local config at ${configPath}`);
  }

  const config = readJsonFile(configPath);
  addCheck(checks, "local_config", "ok", configPath);

  const backendSource = config.backend_source || "repo";
  if (backendSource === "repo") {
    if (!config.backend_repo_path) {
      throw new Error("local-config.json is missing backend_repo_path");
    }

    const backendRepoPath = path.resolve(config.backend_repo_path);
    if (!fs.existsSync(backendRepoPath)) {
      throw new Error(`Configured backend repo was not found at ${backendRepoPath}`);
    }

    addCheck(checks, "backend_repo", "ok", backendRepoPath);
  } else if (backendSource === "package") {
    if (!config.backend_install_root) {
      throw new Error("local-config.json is missing backend_install_root");
    }

    const backendInstallRoot = path.resolve(config.backend_install_root);
    if (!fs.existsSync(backendInstallRoot)) {
      throw new Error(`Configured backend install root was not found at ${backendInstallRoot}`);
    }

    if (!config.backend_package_name) {
      throw new Error("local-config.json is missing backend_package_name");
    }

    const installedPackagePath = path.join(backendInstallRoot, "node_modules", config.backend_package_name);
    if (!fs.existsSync(installedPackagePath)) {
      throw new Error(`Configured backend package was not found at ${installedPackagePath}`);
    }

    addCheck(checks, "backend_package", "ok", installedPackagePath);
  } else {
    throw new Error(`Unsupported backend_source "${backendSource}".`);
  }

  if (!config.bridge_cli_path) {
    throw new Error("local-config.json is missing bridge_cli_path");
  }

  const bridgeCliPath = path.resolve(config.bridge_cli_path);
  if (!fs.existsSync(bridgeCliPath)) {
    throw new Error(`Configured bridge CLI was not found at ${bridgeCliPath}`);
  }
  addCheck(checks, "bridge_cli", "ok", bridgeCliPath);
  addCheck(checks, "node", "ok", process.execPath);

  if (options.smokeTest) {
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "manage-current-session-habits-check-"));
    const tempRegistry = path.join(tempDir, "user_habits.json");
    const sampleTranscript = [
      "user: 以后我说“收尾一下”就是 close_session 场景=session_close",
      "assistant: 收到。",
      "user: 收尾一下"
    ].join("\n");

    try {
      const listParsed = JSON.parse(
        invokeBackend({
          request: "列出用户习惯短句",
          userRegistryPath: tempRegistry,
          configPath
        })
      );
      if (listParsed.action !== "list") {
        throw new Error(`Smoke test list step returned unexpected action: ${listParsed.action}`);
      }

      const scanParsed = JSON.parse(
        invokeBackend({
          request: "扫描这次会话里的习惯候选",
          transcript: sampleTranscript,
          userRegistryPath: tempRegistry,
          configPath
        })
      );
      if (scanParsed.action !== "suggest") {
        throw new Error(`Smoke test scan step returned unexpected action: ${scanParsed.action}`);
      }
      if (scanParsed.candidate_count < 1) {
        throw new Error("Smoke test scan step returned no candidates.");
      }
      if (!scanParsed.assistant_reply_markdown) {
        throw new Error("Smoke test scan step did not return assistant_reply_markdown.");
      }
      if (!scanParsed.suggested_follow_ups) {
        throw new Error("Smoke test scan step did not return suggested_follow_ups.");
      }
      if (!scanParsed.candidate_previews || scanParsed.candidate_previews.length < 1) {
        throw new Error("Smoke test scan step did not return candidate_previews.");
      }
      if (!scanParsed.candidate_previews[0].evidence_summary) {
        throw new Error("Smoke test scan step did not return evidence_summary in candidate_previews.");
      }
      if (!scanParsed.next_step_assessment) {
        throw new Error("Smoke test scan step did not return next_step_assessment.");
      }

      const applyParsed = JSON.parse(
        invokeBackend({
          request: "添加第1条",
          userRegistryPath: tempRegistry,
          configPath
        })
      );
      if (applyParsed.action !== "apply-candidate") {
        throw new Error(`Smoke test apply step returned unexpected action: ${applyParsed.action}`);
      }
      if (applyParsed.applied_rule.phrase !== "收尾一下") {
        throw new Error(`Smoke test apply step returned unexpected phrase: ${applyParsed.applied_rule.phrase}`);
      }
      if (applyParsed.applied_rule.normalized_intent !== "close_session") {
        throw new Error(`Smoke test apply step returned unexpected intent: ${applyParsed.applied_rule.normalized_intent}`);
      }
      if (!applyParsed.assistant_reply_markdown) {
        throw new Error("Smoke test apply step did not return assistant_reply_markdown.");
      }
      if (!applyParsed.next_step_assessment) {
        throw new Error("Smoke test apply step did not return next_step_assessment.");
      }

      addCheck(checks, "smoke_test_list", "ok", "Wrapper list invocation succeeded.");
      addCheck(checks, "smoke_test_scan", "ok", "Wrapper scan invocation succeeded with chat-ready bridge fields.");
      addCheck(checks, "smoke_test_apply", "ok", "Wrapper apply invocation succeeded by reusing the cached suggestion.");
    } finally {
      removePath(tempDir);
    }
  }

  return checks;
}

function main() {
  const parsed = parseArgs(process.argv.slice(2), buildOptionDefs());
  const checks = checkInstall(parsed.values);
  for (const check of checks) {
    console.log(`[${check.status.toUpperCase()}] ${check.name} - ${check.detail}`);
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

module.exports = {
  checkInstall
};
