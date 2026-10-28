---
type: agent
title: "assistant"
description: "汎用のエージェント（例）。Claude Code 上で本人と対話し、vault の整理・記録・計画を担う"
tags: [ai-agents]
aliases: []
status: stable
created: 2026-10-29
actor_id: assistant
previous_actor_ids: []
role: general
runtime: claude-code
model: claude-opus-5-5
account: "本人の個人の Claude アカウント"
instructions: "~/.claude/CLAUDE.md"
personality: ""
tone: ""
---

# assistant

エージェント台帳の例。`generated.by: assistant/<モデル ID>` と書かれた記録は、このエージェントを指す。
名前は好きに付けてよい（元の vault では、本人が付けた名前で呼んでいる）。

## 識別の決まり

- 行為者の書式は `<actor_id>/<モデル ID>`。モデルが変わったら `model` を更新する（履歴は git に残る）
- 改名したら、古い名前を `previous_actor_ids` と `aliases` に残す。書いた時点の名前が事実なので、過去の記録は書き換えない
- 名乗りは自己申告にすぎない。信頼性は、モデル ID・セッションの URL・コミットの `Co-Authored-By` といった実行時の事実で担保する
- エージェントはセッションをまたいだ記憶を持たない。毎回 `instructions` を読み込むことで、このエージェントになる

## 人格

- `personality`（性格）と `tone`（口調）は、将来ほかの実行基盤で指定できるように枠だけ用意してある
- 空のあいだは、`2-Areas/self/profile.md` のコミュニケーションの好みに従う
