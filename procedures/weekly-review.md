---
type: playbook
title: "週次レビュー"
description: "エージェントが下ごしらえし、本人が判断する GTD の週次レビュー（Get clear / Get current / Get creative）"
tags: [gtd, procedure, weekly-review]
status: stable
created: 2026-09-23
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T20:20:48+09:00 }
verified: { by: human:owner, at: 2026-10-01T14:02:45+09:00 }
---

# 週次レビュー

GTD の Reflect の段。**エージェントが下ごしらえし、本人が判断する。** 定時の下ごしらえは暫定で
systemd のユーザータイマーが起動する（`process:weekly-review-timer`）。本人が `/weekly-review` で呼んでもよい。

## 下ごしらえ（エージェント）

`templates/weekly-review.md` から `daily/{YYYY}-W{ww}.md`（ISO 週）を作り、次を埋める。
**下ごしらえでは状態を書き換えない**（下の「集計」だけは例外）。案は案として書き、判断を待つ。

**先に事実を1回で出す:** `nix shell nixpkgs#yq-go nixpkgs#jq nixpkgs#taskwarrior3 -c bash procedures/review-facts.sh`。
下の各項目のうち、数え上げ（一覧・件数・比率・緊急度）はこの出力をそのまま使い、ノートを読んで数え直さない。
エージェントが足すのは、判定と案だけにする。

### Get clear
- `0-Inbox/` に残っている捕獲物の数と、それぞれの仕分けの案
- 今週の daily のログから、タスクになっていない約束や行動の拾い漏れ

### Get current
- **止まっている Project**（事実は `review-facts.sh`）: `status: active` なのに、`next` の付いた未完了のタスクが無いもの。
  それぞれに次の行動の案を出す
- **期限切れと、7日以内が期限のもの**（`review-facts.sh`。繰り返しの回は件数だけ出る）
- **連絡待ちで7日以上動いていないもの**。催促の案
- **見積もりと実績**: 今週完了したタスクの見積もりの合計・実績の合計・比率（`review-facts.sh`。直近7日。比率は見積もりと実績の両方があるものだけで出る）。
  比率が偏っていれば、見積もりの補正の案
- **期限の無い Project**: 期限の案
- **Area の基準**: 各 Area の `standard` を、定義の「維持する基準」に書いた事実で判定する（満たす／下回る／
  未判定）。下回っていれば、戻すためのタスクの案を出す。事実を確かめる手段が無ければ「未判定」と理由を書き、
  推測で満たすとしない。`standard` が空の Area は飛ばす

### Get creative
- `someday` のタスクと Project の中から、動かす候補
- 進行中の Project が無い目標（`type: goal`）
- 未検証の知識（`review-facts.sh`）の一覧。本人に確認してほしいものを上に
- `stale_after` を過ぎた知識

### 来週の予定の案（scheduled）
- 先に、来週の繰り返しの回を**書かずに**読む（`DRY_RUN=1 RECUR_LIMIT=7` で生成スクリプトを流す）。
  回の数は親ごとに7つなので、来週の分だけ拾う。回を作るのは日次の計画（`procedures/plan-day.md`）で、
  来週の回は動かさないブロックとして扱う
- 入力: 緊急度（`review-facts.sh` の「次の行動の緊急度」。Taskwarrior の既定の係数で計算した値を正本とし、
  `views/next-actions.base` の式は Obsidian で見るための写しとする）・`priority`・`estimate`・`depends`・すでに入っている
  `scheduled`・来週の繰り返しの回・`2-Areas/self/profile.md` の特性
- 出力: 「タスク → 日時」の表。**書き込むのは本人が承認したものだけ**
- カレンダーの空きはまだ読めない（未実装）。既知の予定は本人に聞く

### 集計（下ごしらえで書き換えてよい唯一の状態）
- タスクの `actual` を Project ごとに合計して Project の `actual` に、Project を目標ごとに合計して
  目標の `actual` に書く。`bash procedures/sum-actuals.sh` で行い、出力（変わった値）を daily のログに写す

## 判断（本人）

下ごしらえを見て、案ごとに採る・直す・捨てるを決める。エージェントは決まったものを反映し、
daily のログに残して、週次レビューのファイルを `status: completed` にする。

## 定時で動くときの制約

- 本人に質問できないので、判断が要るものはすべて案として書き残す
- コミットはローカルだけ（push は次の対話セッションで行う）
- 完了したらデスクトップに通知を出す
