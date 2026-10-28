---
okf_version: "0.2"
---

# vault

人間と AI エージェントの共有メモリ。GTD が仕分け、PARA が入れ物。知識は OKF v0.2、タスクは Taskwarrior 準拠。
規約は [CLAUDE.md](CLAUDE.md)。`status` の意味は `type` で決まる（知識は OKF の寿命、タスクは Taskwarrior の状態）。

# 入れ物（PARA）

* [0-Inbox](0-Inbox/) - 捕獲。人間は quick.md、エージェントは {date}/{source}/。clarify で仕分けて空にする
* [1-Projects](1-Projects/) - 複数の行動で達成する成果（GTD の Project）。定義・タスク・資料
* [2-Areas](2-Areas/) - 責任の領域（GTD の Area of focus）。定義・目標・単発のタスク・参照
* [3-Resources](3-Resources/) - 関心・参照だけの知識
* [4-Archive](4-Archive/) - 完了・中止した Project と、休止した Area

# 仕組み

* [procedures](procedures/) - 捕獲・仕分け・実績の記録・週次レビューの手順書（どの実行基盤もこれを読む）
* [views](views/) - GTD のリスト（次の行動・今日・連絡待ち・いつか・完了ログ・週次レビュー）を出す Obsidian Bases
* [templates](templates/) - note / task / project / goal / area / daily / weekly-review の雛形
* [daily](daily/) - 1日1ファイルのログと監査面。週次レビューは YYYY-Www.md
* [integrations](integrations/) - 実行基盤への組み込み（Claude Code・定時実行の Nix モジュール・Android の同期）
