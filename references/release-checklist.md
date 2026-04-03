# Skill Release Checklist

Use this checklist before sharing this skill repo with another user or treating it as marketplace-ready.

## Contract Checks

- Confirm [SKILL.md](/E:/manage-current-session-habits/SKILL.md) still matches the actual wrapper behavior.
- Confirm [references/backend-contract.md](/E:/manage-current-session-habits/references/backend-contract.md) still matches the configured backend bridge contract.
- If the backend checkout changed its bridge request or response shape, update this skill repo in the same change set.
- If the backend checkout includes `docs/codex-current-session-contract.md`, confirm this repo still aligns to it.

## Install And Smoke Checks

Run from the skill repo root:

```powershell
& .\scripts\install-skill.ps1 -BackendRepoPath <path-to-user-habit-pipeline> -CheckOnly
& .\scripts\check-install.ps1 -SmokeTest
```

Passing smoke should now verify:

- install link resolution
- local config resolution
- wrapper `list` flow
- wrapper current-session `scan` flow
- chat-ready bridge fields such as `assistant_reply_markdown`, `suggested_follow_ups`, and `next_step_assessment`

## Portability Checks

- Confirm public docs do not rely on author-machine absolute paths as the only supported install path.
- Confirm machine-local paths remain confined to generated `config/local-config.json`.
- Confirm backend resolution still works through parameter, environment variable, or sibling repo layout.
- Confirm no public file requires users to inspect Codex private thread-storage paths.

## Publishing Checks

- Confirm [README.md](/E:/manage-current-session-habits/README.md) still explains install, upgrade, and smoke verification clearly.
- Confirm [agents/openai.yaml](/E:/manage-current-session-habits/agents/openai.yaml) still describes the skill entry surface accurately.
- Confirm tracked config remains template-only:
  - [config/example.local-config.json](/E:/manage-current-session-habits/config/example.local-config.json)
- Confirm generated machine-local config is not being prepared as public contract:
  - `config/local-config.json`

## Interaction Checks

- Confirm the skill still prefers backend-provided `assistant_reply_markdown` over ad hoc paraphrase.
- Confirm the skill still prefers backend-provided `suggested_follow_ups` over inventing different prompts.
- Confirm low-ROI stop handling still respects `停` or `跳过` when the bridge signals that the current direction is not worth extending.
- Confirm the skill still does not auto-add habits during scan-only flows.
