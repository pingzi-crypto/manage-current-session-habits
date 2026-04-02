# Interaction Patterns

Use these response patterns to keep the skill easy to operate inside a normal Codex conversation.

## Primary Rule

If the backend returns `assistant_reply_markdown`, prefer using it directly as the visible reply.
If the backend returns `suggested_follow_ups`, prefer those exact prompts over fresh paraphrases.

Only synthesize your own wording when:

- the backend did not return presentation fields
- the user explicitly asked for raw JSON or a deeper explanation
- the current turn needs one short local-context sentence that the backend could not know

Do not paste full structured JSON into the reply unless the user asks for it.

## After A Scan

When the backend returns candidates:

1. Summarize each candidate briefly.
   Prefer `assistant_reply_markdown` directly when the backend provides it.
2. Include:
   - candidate id
   - phrase
   - suggested intent if present
   - confidence
   - risk flags or review-only status
3. End with short next-step prompts the user can copy naturally:
   - `添加第1条`
   - `把第2条加到 session_close 场景`
   - `忽略第3条`
   - `删除用户习惯短句: 收尾一下`

If there are no candidates, say that clearly and avoid inventing next actions.

Preferred scan example:

```markdown
这次会话共发现 2 条习惯候选：
1. `c1`「收尾一下」，意图 `close_session`，建议添加，置信度 0.84；会话里出现了明确的短句定义，但场景仍然偏通用。；评分依据：未提供明确场景，保持通用候选；风险：场景未指定
2. `c2`「收工啦」，尚无显式意图，复核候选，置信度 0.55；当前会话里短句重复出现，值得复核，但还不适合直接启用。；评分依据：当前会话重复带来加分 0.00，仅来自当前会话，暂不直接提升为可自动添加；风险：仅单会话证据、缺少显式 intent

你接下来可以直接说：
- `添加第1条`
- `忽略第1条`
- `把第1条加到 session_close 场景`
```

## After Apply

When a candidate is added successfully:

1. Confirm the phrase that was added.
2. Echo the resolved `intent`, `scenario_bias`, and `confidence`.
3. Prefer the backend-provided `assistant_reply_markdown` when present.
4. Keep the wording short and explicit so the user can trust what changed.

Preferred apply example:

```markdown
已添加用户习惯短句「收尾一下」，意图 `close_session`，场景 `session_close`，置信度 0.84。
```

## After Ignore

When a candidate is ignored successfully:

1. Confirm which phrase was suppressed.
2. Say that it will be skipped by future suggestion scans.
3. Do not imply that it became an active habit.

Preferred ignore example:

```markdown
已忽略短句「收工啦」，后续扫描将不再重复建议它。
```

## After List

When listing current habits:

1. Separate additions and removals.
2. Keep the format compact.
3. If the list is long, prefer the most actionable fields first:
   phrase, intent, scenario.

Preferred list example:

```markdown
当前记录：新增 2 条，移除 1 条，忽略建议 1 条。

新增短句：
1. 「收尾一下」 -> `close_session`；场景 `session_close`；置信度 0.86
2. 「复盘一下」 -> `close_session`；场景 `session_close`；置信度 0.84

已移除短句：
1. 「验收」

已忽略建议：
1. 「收工啦」
```

## Guardrails

- Never claim a candidate was saved unless the backend returned a successful apply result.
- Never auto-save candidates after a scan.
- If the cache is missing during `添加第1条`, tell the user to scan the current conversation first.
