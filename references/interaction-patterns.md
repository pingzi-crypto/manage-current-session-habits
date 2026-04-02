# Interaction Patterns

Use these response patterns to keep the skill easy to operate inside a normal Codex conversation.

## After A Scan

When the backend returns candidates:

1. Summarize each candidate briefly.
2. Include:
   - candidate id
   - phrase
   - suggested intent if present
   - confidence
   - risk flags or review-only status
3. End with short next-step prompts the user can copy naturally:
   - `添加第1条`
   - `把第2条加到 session_close 场景`
   - `删除用户习惯短句: 收尾一下`

If there are no candidates, say that clearly and avoid inventing next actions.

## After Apply

When a candidate is added successfully:

1. Confirm the phrase that was added.
2. Echo the resolved `intent`, `scenario_bias`, and `confidence`.
3. Keep the wording short and explicit so the user can trust what changed.

## After List

When listing current habits:

1. Separate additions and removals.
2. Keep the format compact.
3. If the list is long, prefer the most actionable fields first:
   phrase, intent, scenario.

## Guardrails

- Never claim a candidate was saved unless the backend returned a successful apply result.
- Never auto-save candidates after a scan.
- If the cache is missing during `添加第1条`, tell the user to scan the current conversation first.
