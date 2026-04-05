# Demo Material Requirements

Use this file when preparing real outward-facing demo assets for `manage-current-session-habits`.

This is the execution template for screenshots, short recordings, and demo-thread capture.
It is meant to turn the existing publishing kit into a concrete production checklist.

## Goal

Produce demo materials that let a first-time viewer understand, in under 90 seconds:

- what the skill does
- how it is triggered inside a normal Codex conversation
- what the review / confirm loop looks like
- why it is different from manual script-driven habit management
- how the low-ROI stop path works

## Required Demo Functions

Record or capture all of these:

1. current-session scan
2. candidate identification from visible thread context
3. explicit confirmation with `添加第1条` or equivalent
4. ignore path with `忽略第1条` or equivalent
5. current state inspection with `列出用户习惯短句`
6. low-ROI stop with `停`

If any of these are missing, the demo set is incomplete.

## Minimum Deliverables

Produce at least:

- 1 short recording
- 5 screenshots
- 1 saved demo-thread transcript or recording script

Recommended structure:

- `demo-video-short`
- `screenshot-01-readme-quick-start`
- `screenshot-02-thread-before-scan`
- `screenshot-03-scan-result`
- `screenshot-04-apply-result`
- `screenshot-05-stop-result`

## Recording Template

Target length:

- short version: 30 to 45 seconds
- full version: 60 to 90 seconds

Recommended sequence:

1. show an existing Codex conversation containing either:
   - an explicit phrase definition
   - or a repeated short phrase
2. type `扫描这次会话里的习惯候选`
3. pause long enough to show the returned candidate summary and follow-ups
4. type `添加第1条`
5. pause long enough to show the saved phrase, intent, and scenario
6. optionally type `列出用户习惯短句`
7. type `停`
8. show that the current low-ROI direction stops cleanly

## Screenshot Checklist

Capture these exact states when possible:

1. README top section with `Quick Start`
2. Codex thread before running a scan
3. scan result showing:
   - candidate summary
   - follow-up prompts
   - visible Chinese chat-ready output
4. apply result showing:
   - saved phrase
   - intent
   - scenario
5. stop result showing:
   - `停`
   - the stop confirmation reply

Optional extra screenshots:

- ignore result
- list result
- install smoke success

## Demo Thread Template

Use a thread like this for the simplest explicit-definition demo:

```text
user: 以后我说“收尾一下”就是 close_session 场景=session_close
assistant: 收到。
user: 收尾一下
user: 扫描这次会话里的习惯候选
assistant: 这次会话共发现 1 条习惯候选……
user: 添加第1条
assistant: 已添加用户习惯短句「收尾一下」……
user: 列出用户习惯短句
assistant: 当前记录：新增 1 条……
user: 停
assistant: 当前这个方向先停。
```

Use a thread like this for the review-only demo:

```text
user: 收工啦
assistant: 你是想结束当前线程吗？
user: 先不用正式收口。
user: 收工啦
user: 收工啦
user: 扫描这次会话里的习惯候选
assistant: 这次会话共发现 1 条习惯候选……
user: 忽略第1条
assistant: 已忽略短句「收工啦」……
```

## Recording Rules

Do:

- record inside a normal Codex conversation surface
- keep the visible flow natural and short
- show user prompts exactly as they would really be typed
- preserve the explicit-confirmation boundary

Do not:

- make the user hunt for transcript files
- foreground shell commands as the main user workflow
- fake auto-learning or implicit save behavior
- hide the `停` path if the demo already enters low-ROI territory

## Acceptance Criteria

The demo set is acceptable when:

- a new viewer can tell this is an in-thread Codex skill
- the scan step is visible
- the confirm or ignore step is visible
- the stop step is visible
- the materials do not imply hidden storage scraping or automatic workflow execution

## Packaging Notes

Pair this file with:

- [publishing-kit.md](/E:/manage-current-session-habits/references/publishing-kit.md)
- [release-checklist.md](/E:/manage-current-session-habits/references/release-checklist.md)

Use `publishing-kit.md` for outward-facing copy.
Use this file for execution and asset production.
