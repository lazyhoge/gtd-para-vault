---
type: playbook
title: "実績の記録"
description: "本人の「始める」「中断」「終わった」から、タスクの start・intervals・actual・status を埋める手順"
tags: [gtd, taskwarrior, procedure]
status: stable
created: 2026-09-23
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T20:20:48+09:00 }
verified: { by: human:owner, at: 2026-10-01T14:02:45+09:00 }
---

# 実績の記録

本人は時刻を手で入れない（手入力は続かない前提）。**エージェントが会話から埋める。**
時刻は、その発言を受け取った時点の現在時刻（`date +%Y-%m-%dT%H:%M:%S`、日本時間）を使う。

## 意味（Taskwarrior・Timewarrior に合わせる）

| 項目 | 意味 |
|---|---|
| `start` | **今まさに作業中の区間が始まった時刻**（Taskwarrior の active）。作業中でなければ空 |
| `intervals` | 閉じた作業区間の一覧（`開始/終了`）。Timewarrior の記録に当たる |
| `actual` | `intervals` の合計（分）。区間を閉じるたびに計算し直す |
| `end` | 完了（または削除）した時刻 |

初めて着手した時刻は `intervals` の最初の区間の開始で分かるので、別に持たない。

## 発言ごとの操作

| 本人の発言の例 | 操作 |
|---|---|
| 「〇〇を始める」「再開」 | `start` に現在時刻を入れる。`status: waiting` なら `pending` に戻す |
| 「中断」「休憩」「いったん止める」 | `start/現在時刻` を `intervals` に足し、`start` を空にする。`actual` を計算し直す |
| 「終わった」「できた」 | 作業中なら区間を閉じる。`end` に現在時刻、`status: completed`、`tags` から `next` を外す。`actual` を計算し直す |
| 「やめた」「不要になった」 | 区間を閉じ、`end` に現在時刻、`status: deleted` |
| 「さっき30分やった」（事後申告） | 終了を現在時刻、開始を30分前として区間を足す。`annotations` に「事後申告」と残す |

- どの操作でも `modified` を現在時刻にする
- **別のタスクを始めたら、このセッションで作業中にしたタスクは自動で中断し、そのことを本人に伝える**
  （1つのセッションで同時に作業中にしない）。ほかの `start` は、並行する別のセッションのものかもしれないので
  触らず、作業中が複数あることを伝えるだけにする。`/clear` の前に始めたものなど、どのセッションのものか
  分からなければ、ほかのセッションのものとして扱う
- どのタスクか曖昧なら、`procedures/vault-query.sh next` の出力から候補を選択肢で出して聞く。該当するタスクが無ければ、仕分けの手順
  （[[clarify]]）で作ってから記録する
- daily のログに「HH:mm 〇〇を始めた（エージェントが記録）」のように1行ずつ残す

## Project に属するタスクを完了したら

その Project に `next` のタスクが残っていなければ、次の行動を本人に聞くか、分解を提案する。
何も残らないなら、完了条件が満たされているのを確かめて Project を完了にし（`status: completed`、フォルダを `4-Archive/` へ移す）、本人に報告する。
