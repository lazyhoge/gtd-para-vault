---
type: readme
title: "定時実行（Nix・home-manager）"
description: "毎朝の繰り返しの手入れと、週次レビューの下ごしらえを systemd のユーザータイマーで動かす home-manager のモジュール"
tags: [vault, nix]
status: stable
created: 2026-10-29
---

# 定時実行（Nix・home-manager）

`knowledge.nix` は home-manager のモジュールで、次の3つを入れる。vault が `~/vault` にある前提。

| コマンド | タイマー | 中身 |
|---|---|---|
| `lh-vault` | なし | `procedures/vault-query.sh` に依存（yq-go・jq・gawk）を揃えて PATH に出す |
| `lh-recur` | 毎朝 4:00 | `procedures/recur-daily.sh`。前の日までの未完了の回の削除・終わった回の片付け・次の回の生成をし、daily に記録してローカルに commit する。AI は起動しない |
| `lh-weekly-review` | 金曜 18:00 | `weekly-review.sh`。Claude Code を非対話（`claude -p`）で起動し、`procedures/weekly-review.md` の下ごしらえを作らせる。終わったら通知を出す |

```nix
# home.nix
imports = [ ~/vault/integrations/nix/knowledge.nix ];
```

- タイマーは `Persistent = true` なので、電源が切れていて跨いだ回は、次の起動時に1度だけ走る
- 失敗したら `notify-send` で通知し、ログを `~/.cache/lh-recur.log`・`~/.cache/lh-weekly-review.log` に残す
- `lh-weekly-review` は `--allowedTools` で、読み書きと `git commit` など必要なコマンドだけを許す。
  push はさせない（次の対話セッションで本人の前で行う）
- `claude` は runtimeInputs に入れず、システムに入っているものを PATH から引く

Nix を使わない場合は、同じことを cron や launchd で行えばよい。依存は `yq`（mikefarah/yq、v4）・`jq`・`task`（Taskwarrior 3）・`gawk`・`git`。
