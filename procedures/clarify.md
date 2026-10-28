---
type: playbook
title: "仕分け（Clarify と Organize）"
description: "0-Inbox/ の捕獲物を GTD の判定表で仕分け、PARA の入れ物にタスク・Project・知識として置く手順"
tags: [gtd, para, procedure]
status: stable
created: 2026-09-23
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T20:20:48+09:00 }
verified: { by: human:owner, at: 2026-10-01T14:02:45+09:00 }
---

# 仕分け（Clarify と Organize）

GTD の2段目と3段目。**捕獲物ごとに、1つずつ、上から**判定する。仕分けた結果は PARA の入れ物に置き、
何をどこへ置いたかを daily のログに1行ずつ残す。

## 判定表

1. **これは何か？** 一文で言えないなら、本人に聞く（自由記述を求めず、候補を選択肢で出す）
2. **行動が要るか？**
   - 要らない →
     - 不要 → 捨てる（`quick.md` の行を消すのは本人の承認後）
     - いつか → `tags: [someday]` のタスク、または `status: someday` の Project
     - 参照 → 知識ノート（OKF）。**未検証として書く**（`verified` を付けない）
   - 要る → 3 へ
3. **望む結果は何か？ 2手以上かかるか？**
   - 2手以上 → **Project**（`1-Projects/<slug>/<slug>.md`）。完了条件（`outcome`）を書き、
     最初の次の行動を1つ以上タスクにする
   - 1手 → 4 へ
4. **次の行動は何か？**（1回の物理的な動作として書く。「〜を検討する」ではなく「〜の候補を3つ書き出す」）
   - 2分以内でできる → その場でやる。エージェントがやれるならやり、本人がやるなら今やるよう伝える
   - 人に頼む → `tags: [waiting]` と `waiting_on`
   - 日時が決まっている → `scheduled`（と `due`）
   - それ以外 → `tags: [next]`

## 置き場所（PARA）

| もの | 置き場所 |
|---|---|
| Project の定義・タスク・資料 | `1-Projects/<slug>/` |
| Project に属さない単発のタスク | 関係する `2-Areas/<area>/` |
| 目標（1〜2年） | 支える `2-Areas/<area>/` に `type: goal` |
| 参照だけの知識 | 関係する Area、どの Area にも属さなければ `3-Resources/<topic>/` |
| 本人についての知見 | `2-Areas/self/`（`profile.md` への反映は本人の確認後） |

どの Area にも合わないものが続けて出たら、新しい Area を作る前に本人に聞く。

## タスクを作るとき（Taskwarrior 準拠。雛形は `templates/task.md`）

- ファイル名は英小文字のケバブケース（`find-lr-series.md`）。`description` は日本語でよい
- `uuid` は `cat /proc/sys/kernel/random/uuid` で作る
- `entry` と `modified` は現在時刻（`YYYY-MM-DDTHH:mm:ss`、日本時間）
- **`priority` を付け、理由を `annotations` に1行残す**:
  - `H` — 目標や、成果物・生活の質に直結する
  - `M` — 大事だが、今週動かなくても害が小さい
  - `L` — やれたら良い
  - 重要度はタスクの価値だけで決める。期限（`due`）と、他のタスクを止めているか（`depends`）は緊急度の式が
    自動で足すので、重要度には入れない
  - 迷ったら `2-Areas/self/profile.md` の「価値観・判断基準」を基準にする
- **`estimate`（分）を付ける。** `views/done-log.base` の過去の「実績/見積」を見て補正する
- 順序があるなら `depends` に先のタスクを入れる
- Taskwarrior の `parent` は、繰り返しの回が親を指すときだけ使う（回はスクリプトが作るので、仕分けでは付けない）

## 分解（Natural Planning Model）

- 本人の話から「道筋が見えた」気配があったら（「あとは〜すればいい」など）、残りを次の行動に分解して提案する
  （手が止まりやすい箇所への手当て。本人の癖は `2-Areas/self/profile.md` に書く）
- 手順のメモで足りるなら、タスク本文のチェックボックスにする
- 手順ごとに予定・実績を追いたいなら、そのタスクを Project に格上げし、手順をタスクにする

## 知識ノートを書くとき（OKF。雛形は `templates/note.md`）

- 1ノート1主張。自分の言葉で書く
- `generated: { by: <actor_id>/<モデル ID>, at: <時差付きの日時>, session: <URL> }`
- `sources` に出どころ（capture、daily、URL）を書く
- `verified` は付けない。本人が確認したら付ける

## 終わったら

- 処理した capture は、エージェントの捕獲なら削除してよい（中身は仕分け先と daily に残っているため）。
  `quick.md` の行は、本人の承認を得てから消す
- daily のログに「何を・どこへ」を1行ずつ書く
