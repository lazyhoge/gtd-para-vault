---
type: readme
title: "Claude Code への組み込み"
description: "Claude Code がこの vault の規約と手順に従って動くための、ユーザー設定（~/.claude/CLAUDE.md）と skill の置き方"
tags: [vault, claude-code]
status: stable
created: 2026-10-29
---

# Claude Code への組み込み

手順の正本は `procedures/` にあり、Claude Code 側には「どこを読むか」と「いつ動くか」だけを置く。
実行基盤を替えても `procedures/` はそのまま使える。

## 1. ユーザー設定（`~/.claude/CLAUDE.md`）

どのディレクトリで起動しても vault の仕組みに従うように、ユーザー全体の指示に次を入れる。
`<名前>` はエージェントに付けた名前（`2-Areas/ai-agents/` の台帳の `actor_id`）。

```markdown
# ユーザーについて

正本は `~/vault/2-Areas/self/`。以下はその要約（編集は vault 側で行う）。

@~/vault/2-Areas/self/profile.md

## あなた（<名前>）

あなたは vault に書くエージェント **<名前>**（識別子 `<actor_id>`、役割は汎用）である。
定義は `~/vault/2-Areas/ai-agents/<actor_id>.md`。

- vault に知識を書くときは、OKF の `generated` を `{ by: <actor_id>/<モデル ID>, at: <時差付きの日時>, session: <このセッションの URL> }` にする
- モデル ID が台帳の `model` と違ったら、台帳の更新を提案する

## vault の仕組み（GTD × PARA）

規約は `~/vault/CLAUDE.md`、手順は `~/vault/procedures/`。

- **実績の記録**: 本人が作業を「始める」「中断」「終わった」と言ったら、`~/vault/procedures/record-actuals.md` に
  従ってタスクの時刻を記録する（本人は時刻を手で入れない）
- **捕獲と仕分け**: 会話でやること・約束・知見が出たら、`~/vault/procedures/clarify.md`（`/clarify`）で
  vault に入れる。タスクと Project は自由に作ってよく、知識は未検証として書く。変えたものは daily のログに残す
- vault に commit するときは、直前に `git diff` で他のセッションの変更が混ざっていないか確かめる
- **セッションの区切り**: タスクが終わったら、結果と次の一手をタスクの本文と daily に書き終えてから、
  `/clear` を提案する

## 自己知見の更新

会話の中で、上の要約と食い違う言動や、要約に無い新しい自己知見（価値観・行動パターン・
コミュニケーションの好み・仕事）に気づいたら、承認を待たずに書き、書いたことを一言伝える。

- `~/vault/daily/{今日}.md` のログに候補として書き、`2-Areas/self/` の主張ノートにも未検証で書く
- 本人の確認は、週次レビューの「未検証の知識」でまとめて受ける
- `profile.md` には、本人が確認した（`verified: human:<名前>`）内容だけを入れる
- 根拠が本人の発言か、観察した行動か、推測かを区別して書く。推測は `guess` と明記する
- vault の規則や設定ファイルの内容は、本人の価値観の根拠にしない
```

- `@~/vault/2-Areas/self/profile.md` の import で、本人の要約が全セッションの前提になる。import は起動時に全文が
  展開されるので、profile は小さく保つ（規約の「profile」の節）
- 最後の「vault の規則を価値観の根拠にしない」は、AI の助言で決めた規則が「本人の好み」として profile に
  逆流するのを防ぐためのもの

## 2. skill

`skills/` の2つを `~/.claude/skills/` に置く（コピーか symlink）。中身は「`procedures/` の該当ファイルを読んで、
そのとおりに進める」だけで、手順そのものは書かない。

```sh
ln -s ~/vault/integrations/claude-code/skills/clarify ~/.claude/skills/clarify
ln -s ~/vault/integrations/claude-code/skills/weekly-review ~/.claude/skills/weekly-review
```

- `/clarify` — `0-Inbox/` の捕獲物を仕分ける
- `/weekly-review` — 週次レビューを下ごしらえする。定時の起動（`integrations/nix/`）からも呼ばれる
