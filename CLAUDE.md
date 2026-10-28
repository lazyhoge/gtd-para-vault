---
type: contract
title: "vault 契約"
description: "人間と AI エージェントが共有するこの vault の構成・形式・権限・禁止事項の正本"
tags: [vault]
status: stable
created: 2026-08-02
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T20:23:19+09:00 }
---

# vault 契約

この vault は、人間と AI エージェントの共有メモリである。
正本は Markdown ファイルそのものであり、特定のツールの内部記憶ではない。

- **仕組み**: GTD が仕分け、PARA が入れ物（→ GTD × PARA の節）
- **形式**: 知識は OKF v0.2、タスクは Taskwarrior 準拠（→ 2つの形式の節）。vault 全体が1つの OKF の束である

## ドメイン

| パス | 内容 | 書き手 |
|---|---|---|
| `0-Inbox/quick.md` | 人間の即時捕獲。追記専用のキュー | 人間 |
| `0-Inbox/{YYYY-MM-DD}/{source}/` | 未整理の生データ（エージェントや会話源の捕獲）。auto-route しない | エージェント |
| `1-Projects/<slug>/` | PARA の Project ＝ GTD の Project。定義 `<slug>.md`・タスク・資料 | 人間 + エージェント |
| `2-Areas/<area>/` | PARA の Area ＝ GTD の Area of focus。定義 `<area>.md`・目標・単発のタスク・参照 | 人間 + エージェント |
| `2-Areas/self/` | 本人についての知見。`profile.md` は `~/.claude/CLAUDE.md` から import され、全セッションで読まれる | 人間 + エージェント |
| `2-Areas/ai-agents/` | エージェント台帳（どの AI が書いたかを引く先） | 人間 + エージェント |
| `3-Resources/<topic>/` | 関心・参照 | 人間 + エージェント |
| `4-Archive/` | 完了・中止した Project、休止した Area（フォルダごと移す）。終わった繰り返しの回（`recurring/YYYY-MM/`。毎朝の定時実行が月ごとに移す） | 人間 + エージェント |
| `daily/{YYYY-MM-DD}.md` | 1日1ファイル。ログと人間の監査面。週次レビューは `daily/{YYYY}-W{ww}.md` | 人間 + エージェント |
| `views/*.base` | Obsidian Bases の一覧（GTD のリスト） | エージェント |
| `views/home.md` | ホーム。今日・次の行動・連絡待ち・進行中の Project と目標を一覧の埋め込みで並べる（`type: dashboard`） | エージェント |
| `procedures/` | ツールに依存しない手順書。どの実行基盤もこれを読んで動く | 人間の承認を得てからエージェント |
| `templates/` | 雛形 | 人間の承認を得てからエージェント |
| `integrations/` | 実行基盤への組み込み（Claude Code の設定と skill・定時実行の Nix モジュール・Android の同期） | 人間の承認を得てからエージェント |

各ディレクトリの `index.md` は OKF の目次で、エージェントがノートの `description` から生成して保つ
（`procedures/gen-index.sh`。ノートを足したり動かしたりしたら流し直す）。

## 原則

1. **知識は、エージェントが未検証として書いてよい。確認済みかどうかは `verified` で表す。**
   `verified` の無い知識は未検証であり、エージェントはそれを確立した知識として扱わない（引用するときは
   未検証だと明示する）。AI が生成した未検証の内容が、時間を置いて「確立された知識」として戻ってくるのを防ぐ
   ための規則で、この vault で最も重要である。本人が確認したら `verified: {by: human:owner, at: …}` を付ける。
   **`2-Areas/self/profile.md` には、本人確認済みの内容だけを入れる**
2. **状態（task / project / goal / area）は、エージェントが自由に作成・更新・移動してよい。** 変えた内容は
   daily のログに1行ずつ残す
3. 捕獲物は必ず clarify（`procedures/clarify.md`）を経て PARA に置く。`0-Inbox/` から判断の痕跡なしに直接
   置かない。判断の痕跡は daily に残す
4. `daily/` から記録を削除しない。監査面であるため、誤りは追記で訂正する
5. すべての `.md` に frontmatter と `type` を付ける（OKF の準拠条件）
6. 不確実な情報は `guess` / `unverified` と明示する。断定しない
7. **規約（このファイル）・`procedures/`・`templates/`・`integrations/` の変更は、人間の承認を得てから行う。** エージェントの
   振る舞いを決めるファイルなので、エージェントが自分で書き換えない

## GTD × PARA

GTD で仕分けたタスクの集まりが、PARA の Project や Area になる。1つの入れ物に、定義・タスク・知識が同居する。

| GTD | PARA | 入れ物の中身 |
|---|---|---|
| Project（複数の行動で達成する成果） | Project | 定義（`type: project`）＋ タスク ＋ 資料 |
| Area of focus（責任の領域） | Area | 定義（`type: area`）＋ 目標 ＋ 単発のタスク ＋ 参照 |
| Reference | Resource | 知識だけ |
| 完了・中止 | Archive | 終わった Project・休止した Area を丸ごと |
| 次の行動（状況別）・連絡待ち・カレンダー・いつか | 入れ物ではない | `views/` の一覧（PARA を横断する） |

### Horizons of Focus（視点の高さ）

| 段 | GTD | 置き場所 |
|---|---|---|
| 5・4 | 目的・原則／3〜5年のビジョン | `2-Areas/self/` のノート |
| 3 | 1〜2年の目標 | `type: goal`。支える Area の中に置く。小目標は `parent` で親の目標を指す |
| 2 | 責任の領域 | Area |
| 1 | プロジェクト | Project。目標を `goal`、親の Project を `parent` で指す |
| 0 | 次の行動 | タスク |

### 分解

- 2手以上かかるものはタスクではなく Project である（GTD の規則）
- 手順のメモで足りるなら、タスク本文のチェックボックスにする（データベースでは追跡しない）
- 手順ごとに予定・実績を追跡したいなら、Project に格上げし、手順をタスクにする。順序は `depends` で表す
- 道筋が見えたら、エージェントが残りの分解を提案する（「道筋が見えたところで手が止まる」への手当て）

### 期限と「いつか」

- PARA の Project は期限を持つ。期限の無い Project には、週次レビューでエージェントが期限の案を出す
- 「いつか」の Project は `1-Projects/` に置いたまま `status: someday` にする

手順の詳細は `procedures/` にある: `capture.md` / `clarify.md` / `record-actuals.md` / `plan-day.md` / `weekly-review.md`。

## 2つの形式

### 知識: OKF v0.2

仕様: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

```yaml
---
type: note                 # 必須
title: "…"
description: "1文の要約"    # index.md と検索に使う
tags: [self, values]
status: stable             # OKF の寿命: draft | stable | deprecated（無ければ stable）
created: 2026-09-23
generated: { by: assistant/claude-opus-5-5, at: 2026-09-23T21:00:00+09:00, session: "<URL>" }
verified: { by: human:owner, at: 2026-09-23T21:30:00+09:00 }
stale_after: 2026-09-28T00:00:00+09:00   # 古くなる時点が分かっているときだけ
sources:
  - { id: d0923, resource: /daily/2026-09-23.md, title: "インタビューの記録" }
resource:                  # 正本が外部にあるときだけ（URL または SoR 識別子）
---
```

- 知識の `type`: `note`（主張）/ `agent`（エージェント台帳）/ `contract`（このファイル）/ `readme`（README）/ `playbook`（手順書）/
  `log`（daily）/ `capture`（捕獲）/ `dashboard`（ホーム。一覧を並べるだけのページ）
- OKF の日時（`generated.at` / `verified.at` / `stale_after`）は時差付きで書く（`+09:00`）
- 本文中の主張ごとの出典は、`sources[].id` を名前にした脚注で付ける
- **1ノート1主張。** ファイル名は主張が分かる名前にする（`dns-consolidation.md`）。例外は
  `2-Areas/self/profile.md` だけ（→ profile の節）
- 引用や出力の貼り付けではなく、**自分の言葉で書き直したもの**を置く
- 関連ノートには `[[wikilink]]` を張る。リンク先が未作成でもよい（OKF も切れたリンクを許容する）。
  標準の Markdown リンクにはしない。PARA ではファイルが動くので、名前で指すほうが切れない

### 行動: Taskwarrior 準拠

仕様: https://github.com/GothenburgBitFactory/taskwarrior/blob/develop/doc/devel/rfcs/task.md

```yaml
---
type: task
uuid: 7f3c2a9e-0000-4000-8000-000000000000
description: 本棚の設置場所の寸法を測る
status: pending            # pending | waiting | completed | deleted | recurring
project: "[[room-renovation]]"
tags: [next, computer]
priority: H                # H | M | L
depends: []
entry: 2026-09-23T21:30:00
modified: 2026-09-23T21:30:00
scheduled: 2026-09-28T19:00:00
due: 2026-09-30
wait:
start:
end:
annotations:
  - { entry: 2026-09-23T21:30:00, description: "priority H: 寸法が決まらないと他の作業が全部止まるため" }
estimate: 60               # UDA: 見積もり（分）
actual: 55                 # UDA: 実績の合計（分）。intervals から計算する
intervals:                 # UDA: 作業した区間
  - 2026-09-28T19:10:00/2026-09-28T20:05:00
waiting_on:                # UDA: 連絡待ちの相手
---
本文はメモ。手順のチェックボックスもここに書く。
```

- 項目名と値は Taskwarrior の JSON 形式に合わせる。違いは次の4つだけで、書き出すときに変換する:
  - 日時は Obsidian の日時型（`YYYY-MM-DDTHH:mm:ss`、日本時間）。Taskwarrior は `YYYYMMDDTHHMMSSZ`（UTC）
  - `project` は wikilink。Taskwarrior では文字列で、階層は点区切り（`room-renovation.furniture`）
  - `depends` はタスクへの wikilink の一覧。Taskwarrior では uuid の一覧
  - `parent`（繰り返しの親）は wikilink。Taskwarrior では uuid
- **`start` は「今まさに作業中の区間が始まった時刻」**（Taskwarrior の active）。中断・完了のときに区間を
  `intervals` へ移して空にする。初めて着手した時刻は `intervals` の最初の区間で分かる（→ `procedures/record-actuals.md`）
- **`status: waiting` は「`wait` の日時まで一覧から隠す」という意味**で、GTD の連絡待ちではない。
  連絡待ちは `tags: [waiting]` と `waiting_on` で表す
- `tags` の語彙:
  - GTD のリスト: `next` / `waiting` / `someday`
  - 状況: `computer` / `home` / `errands` / `phone` / `anywhere` / `agenda`
- `priority` はエージェントが付け、理由を `annotations` に残す。本人はいつでも直してよい
- **繰り返し**は Taskwarrior の recurrence に合わせる:
  - 親: `status: recurring`・`recur`（周期。`daily` / `weekly` / `monthly` / `weekdays` / `3d` など
    Taskwarrior の期間の書式）・`due`（必須）・`until`（任意。過ぎたら親を完了にする）・`mask`（各回の状態）
  - 回: 普通のタスクに `recur`・`parent`（親への wikilink）・`imask`（親の `mask` の何番目か）が付く。
    親と同じフォルダに `<親>-YYYY-MM-DD.md` で置く。終わった回（completed・deleted）は、`due` の月が明けたら
    `4-Archive/recurring/YYYY-MM/` へ移す
  - **回と `mask`・`imask` は手で作らない。** 生成スクリプトが Taskwarrior で生成して書き戻す
    （→ `procedures/generate-recurring.sh`）。Taskwarrior は `scheduled` を回ごとにずらさないので、スクリプトが計算し直す
  - 毎朝 4:00 の定時実行（`procedures/recur-daily.sh`、`process:recur-timer`）が、前の日までの未完了の回の削除・
    終わった回の片付け・次の回の生成をして、daily に記録して commit する。回は各親の次の1回だけ作り、先の回は
    `DRY_RUN=1 RECUR_LIMIT=<回数>` で書かずに見る
  - 続いている習慣も繰り返しのタスクにする。機械が定時に実行するものはタスクにしない
  - やらなかった回は `status: deleted` にし、理由を `annotations` に残す
- 緊急度（urgency）は保存しない。`views/` の計算式で Taskwarrior の既定の係数を再現する

### 入れ物の定義: project / goal / area

| type | 項目 | status |
|---|---|---|
| `project` | `title` / `outcome`（完了条件）/ `due` / `area` / `goal` / `parent` / `actual`（集計） | `active` / `someday` / `completed` / `dropped` |
| `goal` | `title` / `outcome` / `due` / `area` / `parent` / `actual`（集計） | `active` / `achieved` / `dropped` |
| `area` | `title` / `standard`（維持する基準） | `active` / `archived` |

`actual` の集計（タスク → project → goal）は、週次レビューでエージェントが行う。

### `status` の意味は `type` で決まる

| type | status の意味 |
|---|---|
| note / agent / contract / playbook | OKF の寿命（draft / stable / deprecated） |
| task | Taskwarrior の状態 |
| project / goal / area | 上の表の値 |
| log | 1日の締め（`in-progress` / `completed`） |
| dashboard | 使わない |
| capture | `inbox` 固定 |

OKF は `type` で読み分けることを前提にした形式なので、この同居は許容範囲である。

## 書き手（actor）

- OKF の `generated.by` / `verified.by` には、次のどれかを書く:
  - エージェント → `<actor_id>/<モデル ID>`（例: `assistant/claude-opus-5-5`）
  - 本人 → `human:<名前>`（この雛形では `human:owner`）
  - 定時実行など → `process:<名前>`（例: `process:weekly-review-timer` / `process:recur-timer`）
- `<actor_id>` は `2-Areas/ai-agents/` の台帳で引ける名前にする
- `generated.session` にセッションの URL を残す（OKF の拡張キー）
- 名乗りは自己申告なので、信頼性はモデル ID・セッションなど実行時の事実で担保する
- 作り手が分からない過去の記録は `claude-code/unknown` とする

## 即時捕獲（`0-Inbox/quick.md`）

思いついたことを、分類も日付もファイル名も決めずに放り込む単一の投入口。

- **追記専用。** 常に同じ1ファイルであることが価値。日付で分けない、複数ファイルに散らさない
- **キューであってログではない。** clarify で PARA と daily に流し、**空にする**。溜まっている状態が
  「未処理がある」というシグナルになる
- エージェントはここを読んで振り分けを提案してよいが、**空にするのは人間の承認後**
- 書き手は人間。エージェントの capture は `0-Inbox/{YYYY-MM-DD}/{source}/` に書く（single-writer を保つ）
- **モバイル（Android + Termux の git）からの捕獲も同じファイルに入る。** スマホ側の書き込み面はこのファイルだけ（→ `integrations/android/`）
- モバイル由来のコミットは**署名が付かない**（GitHub 上で `Unverified`）。エージェントは署名の欠落を根拠に履歴を疑わない

## ナビゲーション

- タスクと Project は `procedures/vault-query.sh`（PATH にあれば `lh-vault`）の `next` / `tasks` /
  `project <slug>` で引く。ノートを開くのは、出てきた行の中身が要るときだけ
- vault 全体を読み込まない。まず `index.md` と `views/*.base` の条件を見て、frontmatter への grep
  （`type:` / `status:` / `tags:`）で絞ってから読む
- 日付が分かっているものは `daily/{YYYY-MM-DD}.md` から辿る

## profile

`2-Areas/self/profile.md` だけは「1ノート1主張」の例外である。全セッションで読まれる要約なので、複数の主張を
箇条書きで集約し、各行から主張ノートへリンクする。約 1,500 トークン（5KB）以内に保ち、あふれたら主張ノート側へ寄せる。

- 上限を設けている理由: `@` import したファイルは、起動時に全文がコンテキストへ展開される。そのため、**複数
  ファイルに分割して import しても、読み込む量は減らない。** 減らす方法は「毎回の応答に効く行だけを profile に
  残し、特定の話題でだけ効く詳細はリンク先に置いて、必要なときに読ませる」だけである。5KB という数字は、この
  線引きを保つための目安であり、技術的な制約ではない

## この vault でやらないこと

- **Zettelkasten の正典構造を持ち込まない。** 連番 ID のファイル名にしない。fleeting / literature / permanent
  の分類をしない
- `type` / `status` / `tags` の語彙を勝手に増やさない。増やしたくなったら人間に提案する
- 同じ状態を2か所で持たない。外部のタスク管理やカレンダーと同期するときは、どちらが正本かを先に決める

## 構造変更

新規フォルダ・rename・move は、このファイルの対応する記述の更新と同じコミットに含める。
ただし、状態の変化に伴う移動（完了した Project を `4-Archive/` へ移すなど）は、この規約に沿った日常の操作なので
対象外である。
