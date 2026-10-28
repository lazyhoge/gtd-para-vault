---
type: readme
title: "gtd-para-vault"
description: "人間向けの説明。この仕組みの考え方・流れ・構成・導入手順"
tags: [vault]
status: stable
created: 2026-10-29
---

# gtd-para-vault

**GTD で仕分けて PARA の入れ物に置き、記録と整理は AI エージェントが担う**、一人用のタスク・スケジュール管理の仕組み。
Obsidian の vault（Markdown のフォルダ）そのものが正本で、Claude Code などのエージェントが手順書を読んで動く。

本人がやるのは **捕獲（1行放り込む）と判断（承認する）だけ**。分類・時刻の記録・実績の集計・週次レビューの下ごしらえは
エージェントと定時実行のスクリプトが行う。

> 作者が毎日使っている vault から、仕組みの部分（規約・手順書・スクリプト・雛形・一覧）だけを切り出したもの。
> 中身（タスク・日誌・本人についてのノート）は除き、例のデータに差し替えてある。

*English summary: A personal GTD × PARA task and schedule system kept as an Obsidian vault of Markdown files.
Tasks use Taskwarrior-compatible frontmatter, notes use OKF v0.2, and an AI agent (Claude Code) captures, sorts, records
time and prepares weekly reviews by following the tool-agnostic playbooks in `procedures/`. Everything is written in Japanese.*

## なぜこう作ったか

- **意志や記憶に頼らない。** 手で分類する・手で時刻を入れる・思い出してレビューする、という運用は続かない前提で、
  その作業をすべてエージェントと定時実行に寄せた。本人には「始める」「終わった」と言うことと、案を採るかどうかだけが残る
- **正本は Markdown のファイル。** 特定のツールの内部状態を正本にしない。Taskwarrior も Obsidian も、ファイルを読んで計算や表示をするだけ
- **手順はツールから独立させる。** 手順書（`procedures/`）は実行基盤に依存しない言葉で書き、Claude Code の skill は
  「手順書を読め」と指すだけにした。実行基盤を替えても手順書はそのまま使える
- **AI が書いた知識は未検証として扱う。** `verified` が付くまでは確立した知識として扱わない。AI の生成物が
  時間を置いて「事実」として戻ってくるのを防ぐための規則で、この仕組みで最も重要なもの（`CLAUDE.md` の原則 1）
- **変えたことは必ず daily に残す。** エージェントが状態を変えたら `daily/{今日}.md` に1行ずつ書く。daily は
  消さない監査面で、誤りは追記で直す
- **書き手を1つに絞る。** 人間の即時捕獲は `0-Inbox/quick.md` の1ファイルだけ、スマホの書き込み面もこのファイルだけ。
  エージェントの捕獲は別のフォルダに書く。これで同時に書いても競合しない

## 流れ

```
捕獲 ──→ 仕分け ──→ 実行（実績の記録） ──→ 見直し（週次） ──→ 完了したらアーカイブ
0-Inbox/   clarify     「始める」「終わった」    金曜に下ごしらえ      4-Archive/
```

| 段 | 手順書 | 本人 | エージェント |
|---|---|---|---|
| 捕獲 | `procedures/capture.md` | `Ctrl+Shift+A`（QuickAdd）で `0-Inbox/quick.md` に1行 | 会話で出たやること・約束・知見を拾う |
| 仕分け | `procedures/clarify.md`（`/clarify`） | 迷うものに答える（選択肢から選ぶ） | GTD の判定表で Project・タスク・知識に振り分け、重要度（理由つき）と見積もりを付ける |
| 計画 | `procedures/plan-day.md` | 案を行ごとに採る・直す・捨てる | 緊急度の順に今日の空き時間へ割り付けた案を出す |
| 実行 | `procedures/record-actuals.md` | 「始める」「中断」「終わった」と言う | `start`・`intervals`・`actual`・`end` を埋める |
| 見直し | `procedures/weekly-review.md`（`/weekly-review`） | 案を判断する | 止まっている Project・期限・連絡待ち・見積もりと実績・未検証の知識・来週の予定の案を下ごしらえする |
| 繰り返し | `procedures/recur-daily.sh`（毎朝 4:00） | なし | 過ぎた回の削除・終わった回の片付け・次の回の生成 |

## 構成

| パス | 中身 |
|---|---|
| `CLAUDE.md`（`AGENTS.md` は symlink） | **エージェント向けの規約の正本。** 構成・形式・権限・禁止事項 |
| `0-Inbox/` | 捕獲。人間は `quick.md`、エージェントは `{日付}/{出どころ}/` |
| `1-Projects/<slug>/` | PARA の Project ＝ GTD の Project。定義・タスク・資料を1フォルダに |
| `2-Areas/<area>/` | 責任の領域。定義（維持する基準）・目標・単発のタスク・参照 |
| `2-Areas/self/` | 本人についての知見。`profile.md` は全セッションで読まれる要約 |
| `2-Areas/ai-agents/` | エージェントの台帳（どの AI が書いたかを引く先） |
| `3-Resources/` / `4-Archive/` | 参照だけの知識 / 完了した Project と終わった繰り返しの回 |
| `daily/` | 1日1ファイルのログと監査面。週次レビューは `YYYY-Www.md` |
| `procedures/` | 手順書とスクリプト |
| `views/` | GTD のリストを出す Obsidian Bases（次の行動・今日・連絡待ち・いつか・完了ログ・週次レビュー）と、それを並べたホーム |
| `templates/` | task / project / goal / area / note / daily / weekly-review の雛形 |
| `integrations/` | Claude Code の設定と skill・定時実行の Nix モジュール・Android の同期 |

GTD の「次の行動」「連絡待ち」「いつか」は入れ物ではなく、入れ物を横断する一覧（`views/`）として出す。

## 2つの形式

**タスクは Taskwarrior 準拠の frontmatter**（1タスク1ファイル）。項目名と値を Taskwarrior の JSON に合わせてあるので、
`procedures/export-taskwarrior.sh` でそのまま本物の Taskwarrior に取り込める。緊急度や繰り返しの回の生成は、
使い捨ての Taskwarrior に計算させて結果だけを Markdown に書き戻す（Taskwarrior に状態は残さない）。

```yaml
---
type: task
uuid: 7f3c2a9e-1111-4000-8000-000000000001
description: "本棚の設置場所の寸法を測る"
status: completed            # pending | waiting | completed | deleted | recurring
project: "[[room-renovation]]"
tags: [home]                 # next / waiting / someday ＋ 状況（computer / home / errands …）
priority: H                  # 理由は annotations に残す
scheduled: 2026-10-29T08:05:00
due: 2026-10-31
end: 2026-10-29T08:40:00
annotations:
  - { entry: 2026-10-29T08:00:00, description: "priority H: 寸法が決まらないと他の作業が全部止まるため" }
estimate: 20                 # UDA: 見積もり（分）
actual: 30                   # UDA: intervals の合計（分）
intervals:                   # UDA: 作業した区間
  - 2026-10-29T08:10:00/2026-10-29T08:40:00
---
```

**知識は [OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)**（1ノート1主張）。
`generated: { by: <actor_id>/<モデル ID>, at: …, session: … }` で誰が書いたかを、`verified` で本人が確かめたかを表す。

落とし穴と細則（`status: waiting` は「隠す」であって連絡待ちではない、など）は `CLAUDE.md` の「2つの形式」にまとめてある。

## スクリプト（`procedures/`）

| スクリプト | 中身 |
|---|---|
| `vault-query.sh` | タスクと Project を frontmatter から1行ずつ引く（`next` / `tasks` / `project <slug>` / `json`）。エージェントがノートを1本ずつ開かずに済む |
| `export-taskwarrior.sh` | vault のタスクを Taskwarrior の JSON に書き出す |
| `generate-recurring.sh` | 繰り返しの親から次の回を Taskwarrior に生成させ、Markdown に書き戻す。`DRY_RUN=1` で書かずに見る |
| `recur-daily.sh` | 毎朝の手入れ（過ぎた回の削除・終わった回のアーカイブ・次の回の生成・daily への記録・ローカルの commit） |
| `review-facts.sh` | 週次レビューに使う事実（数え上げ）を1回で出す。エージェントは判定と案だけを足す |
| `sum-actuals.sh` | タスクの実績を Project・目標ごとに合計する |
| `gen-index.sh` | 各フォルダの `index.md`（OKF の目次）を frontmatter から作る |

依存: `bash`・GNU coreutils・`gawk`・[`yq`](https://github.com/mikefarah/yq)（v4）・`jq`・`task`（Taskwarrior 3）。
Nix があれば `nix shell nixpkgs#yq-go nixpkgs#jq nixpkgs#taskwarrior3 -c bash procedures/<名前>.sh`。
どれも `VAULT=<パス>` で対象を変えられる（既定は `~/vault`）。

## 試す

この雛形には例のデータ（`1-Projects/room-renovation/`・`2-Areas/home/`）が入っている。

```sh
git clone https://github.com/lazyhoge/gtd-para-vault.git ~/vault
cd ~/vault
bash procedures/vault-query.sh next              # 次の行動
bash procedures/vault-query.sh project room-renovation --all
bash procedures/review-facts.sh                  # 週次レビューの事実
DRY_RUN=1 RECUR_LIMIT=3 bash procedures/generate-recurring.sh
```

## 導入

1. **置く**: このリポジトリを `~/vault` に clone し、例のデータ（`1-Projects/room-renovation/`・`2-Areas/home/` の中身・
   `daily/` の例）を消す。自分の vault は **private** のリポジトリで管理する（本人についての知見と日誌が入るため）
2. **本人の名前を決める**: 規約と手順書の `human:owner` を自分の名前に置き換える（`grep -rl human:owner`）
3. **エージェントに名前を付ける**: `2-Areas/ai-agents/assistant.md` を写して台帳を作る。`generated.by` に出る名前になる
4. **Obsidian**: このフォルダを保管庫として開く。設定は `.obsidian/` に入っている（新規ノートは `0-Inbox/`、
   添付は `_assets/`、デイリーノートは `daily/` と `templates/daily`、`Ctrl+Shift+D` で今日のデイリーノート）
   - コミュニティプラグイン **QuickAdd** を入れて有効化する。Capture の設定（`0-Inbox/quick.md` の末尾に
     `- {{DATE:HH:mm}} {{VALUE}}`、ファイルを開かない）と `Ctrl+Shift+A` の割り当ては同梱してある。
     **いまの画面を離れずに1行放り込める**ことが、即時捕獲が続く条件
   - 一覧は Obsidian の Bases（コアプラグイン）を使う。ホームは `views/home.md`
5. **Claude Code**: `integrations/claude-code/README.md` のとおりに、ユーザー設定（`~/.claude/CLAUDE.md`）と skill を置く
6. **定時実行**（任意）: `integrations/nix/`（home-manager のモジュール。毎朝 4:00 の繰り返しの手入れと、金曜 18:00 の週次レビューの下ごしらえ）
7. **スマホ**（任意）: `integrations/android/`（Termux の git で `0-Inbox/quick.md` だけを同期する）

## 前提と制約

- **日本時間で固定。** frontmatter の日時は時差なしの日本時間で、スクリプトは `TZ=Asia/Tokyo` と +9 時間の換算を
  決め打ちしている。他の時間帯で使うなら `procedures/*.sh` の `Asia/Tokyo` と `32400` を直す
- 規約・手順書・出力はすべて日本語
- GNU の `date -d` を使うので、macOS では coreutils の `gdate` などに置き換えが要る
- 動作を確かめたのは Linux（NixOS）・Taskwarrior 3.4・Obsidian 1.13（Bases）・Claude Code
- カレンダーの空きを読む・外部の窓口（チャットなど）から捕獲する、はまだ無い（予定の案は本人に空きを聞いて作る）

## 本人の特性を仕組みに入れる

この仕組みは、`2-Areas/self/profile.md` に書いた本人の特性（どう説明されたいか、どこで手が止まるか、何を優先するか）を
エージェントが毎回読む前提で作ってある。手順書のいくつかの決まりは、もともと作者の特性への手当てだった:

- 迷ったものは自由記述を求めず、候補を選択肢で出す（`clarify.md`）
- 「あとは〜すればいい」と道筋が見えたところで手が止まるので、そこでエージェントが残りを次の行動に分解する（`clarify.md`・`CLAUDE.md`）
- 過ぎた繰り返しの回は、本人に聞かずに削除する。都度「やったか」を判断させると続かない（`plan-day.md`・`recur-daily.sh`）

自分で使うときは profile を自分のものに書き、合わない決まりは手順書の側を直すとよい。

## ライセンス

[MIT](LICENSE)
