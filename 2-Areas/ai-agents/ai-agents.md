---
type: area
title: "AI エージェント"
description: "vault に書く AI エージェントの台帳。どの AI が書いたかを generated.by から引く先"
status: active
standard: "台帳の model が実際のモデル ID と一致する。定時実行が failed のまま残っていない"
created: 2026-10-29
---

<!-- PARA の Area ＝ GTD の Area of focus。維持する基準（standard）を持ち、目標・単発のタスク・参照を置く -->

## 維持する基準

- 台帳（このフォルダの `type: agent`）の `model` が、実際に動いているモデル ID と一致する
- 定時実行（`lh-weekly-review`・`lh-recur`）が failed のまま残っていない

判定に使う事実: 台帳の `model` と、下ごしらえをしているセッション自身のモデル ID。`systemctl --user list-units --failed`
