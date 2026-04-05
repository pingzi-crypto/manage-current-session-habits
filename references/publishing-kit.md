# Publishing Kit

Use this file when you need ready-to-reuse outward-facing copy for sharing `manage-current-session-habits`.

It is intentionally short and practical:

- one-line positioning
- short and medium listing copy
- demo script
- screenshot checklist

If you are actually producing screenshots or recordings, also use:

- [demo-material-requirements.md](/E:/manage-current-session-habits/references/demo-material-requirements.md)

## One-Line Positioning

Turn the current Codex conversation into reviewable user-habit candidates without leaving the thread.

## Short Listing Copy

Scan the current Codex thread for repeated shorthand or explicit phrase definitions, then confirm or ignore habit candidates in place with short follow-up prompts like `添加第1条` or `忽略第1条`.

## Medium Listing Copy

`manage-current-session-habits` is a Codex skill for people who want habit management to happen inside the normal conversation UI instead of through ad hoc scripts or file hunting.

It lets the user:

- scan the current thread for habit candidates
- review explicit phrase definitions and repeated shorthand
- confirm or ignore candidates with short prompts such as `添加第1条` and `忽略第1条`
- list or remove saved user habit phrases
- stop low-value cleanup quickly with `停`

It keeps the important boundary intact:

- the skill gathers current-thread context
- the backend interprets it
- the user still explicitly confirms durable changes

## GitHub Repo Description

Codex skill for scanning the current conversation for habit candidates and confirming them in place.

## Launch Post Copy

Built a small Codex skill called `manage-current-session-habits`.

It lets me stay inside the current Codex thread and say things like:

- `扫描这次会话里的习惯候选`
- `添加第1条`
- `忽略第1条`
- `列出用户习惯短句`

Instead of finding session files or running manual backend commands, the skill forwards the visible conversation into `user-habit-pipeline`, returns reviewable candidates, and keeps explicit confirmation for anything durable.

## 30-Second Demo Script

Use this when recording or demonstrating the skill:

1. Show a normal Codex conversation with a repeated short phrase or an explicit phrase definition already in the thread.
2. Type:
   - `扫描这次会话里的习惯候选`
3. Show the reply with:
   - candidate summary
   - `assistant_reply_markdown`
   - follow-up prompts such as `添加第1条`
4. Type:
   - `添加第1条`
5. Show the confirmation reply with saved phrase, intent, and scenario.
6. Type:
   - `停`
7. Show that the skill stops the current low-ROI cleanup direction cleanly.

## Screenshot Checklist

If you prepare screenshots for sharing or a marketplace page, capture:

1. README top section with `Quick Start`
2. Codex conversation before scan
3. scan reply showing candidate summary and follow-ups
4. apply reply showing the confirmed saved phrase
5. stop reply showing `停`

## Demo Thread Example

```text
user: 以后我说“收尾一下”就是 close_session 场景=session_close
assistant: 收到。
user: 收尾一下
user: 扫描这次会话里的习惯候选
assistant: 这次会话共发现 1 条习惯候选……
user: 添加第1条
assistant: 已添加用户习惯短句「收尾一下」……
user: 停
assistant: 当前这个方向先停。
```
