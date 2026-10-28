---
name: clarify
description: ~/vault の 0-Inbox/ にある捕獲物を GTD の判定表で仕分け、PARA の入れ物にタスク・Project・知識として置く。「inbox を処理して」「仕分けて」「clarify」と言われたとき、または会話で出たやること・知見を vault に入れるときに使う。
---

手順の正本は `~/vault/procedures/clarify.md` にある。まずそれを読み、そのとおりに進める。
このファイルには手順を書かない（vault 側を唯一の正本にし、Claude Code 以外の実行基盤とも共有するため）。

- vault の規約は `~/vault/CLAUDE.md`。とくに「原則」「2つの形式」「書き手（actor）」に従う
- 書き手は `<actor_id>/<モデル ID>`（`<actor_id>` は `2-Areas/ai-agents/` の台帳の名前）とし、`generated.session` にこのセッションの URL を入れる
- 仕分けた結果は `~/vault/daily/{今日}.md` のログに1行ずつ残す
- コミットは意味単位で分け、直前に `git diff` で他のセッションの変更が混ざっていないか確かめる
