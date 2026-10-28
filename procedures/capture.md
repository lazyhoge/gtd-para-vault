---
type: playbook
title: "捕獲（Capture）"
description: "頭に浮かんだこと・会話で出たことを、分類せずに 0-Inbox/ へ入れる手順"
tags: [gtd, procedure]
status: stable
created: 2026-09-23
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T20:20:48+09:00 }
verified: { by: human:owner, at: 2026-10-01T14:02:45+09:00 }
---

# 捕獲（Capture）

GTD の最初の段。**判断しないで入れる**のが目的なので、ここでは分類も期限も決めない。

## 入れ先

| 書き手 | 入れ先 | 形 |
|---|---|---|
| 人間 | `0-Inbox/quick.md` | 末尾に `- HH:mm 内容` を1行（QuickAdd の `Ctrl+Shift+A`、スマホも同じファイル） |
| エージェント・会話源 | `0-Inbox/{YYYY-MM-DD}/{source}/{slug}.md` | `type: capture` / `status: inbox` の1ファイル |

- `{source}` は出どころの名前（`claude-code` / `discord` / `fediverse` / `claude-ai` / `gemini` など）
- エージェントの capture の frontmatter には、出どころを `resource:`（会話の URL など）に書き、
  `generated: { by: <actor>, at: …, session: … }` を付ける
- `quick.md` の書き手は人間だけ（single-writer）。エージェントは `quick.md` に書かない

## 会話からの捕獲（エージェント）

会話の中で次のものが出たら、その場で capture にするか、すぐ clarify してよい（→ [[clarify]]）:
- やること（本人・エージェント・他人のどれがやるかも）
- 期限や約束
- 後で使えそうな知見
- 本人についての新しい知見（→ `~/.claude/CLAUDE.md` の「自己知見の更新」）

## 溜めない

`0-Inbox/` が2日溜まったら、取り込み源を増やさず減らす。
