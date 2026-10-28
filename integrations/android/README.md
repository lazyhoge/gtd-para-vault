---
type: readme
title: "Android からの捕獲（Termux の git）"
description: "スマホの役割を捕獲と閲覧に絞り、0-Inbox/quick.md への追記だけを Termux の git で同期する設定"
tags: [vault, android]
status: stable
created: 2026-10-29
---

# Android からの捕獲（Termux の git）

**スマホの役割は捕獲と閲覧だけ。** 書き込みは Obsidian の QuickAdd から `0-Inbox/quick.md` へ追記する経路のみで、
それ以外のファイルはスマホからは編集しない。書き込み面を1ファイルに絞ってあるので、デスクトップ側の
エージェントと同時に触っても競合しない（競合しても追記専用なので両方の行を残せば済む）。

同期は **Termux の git**。Obsidian は保管庫を開くだけで、同期に関与しない。

**Obsidian Git（プラグイン）は使わない。** 試した範囲では、App storage 以外では `Directory does not exist`、
App storage では clone がエラーで終わって `.git` が残らなかった。公式ドキュメント自身が「モバイルの Git 実装は
非常に不安定」と書いている。

## 準備

認証は **書き込み権限付きの SSH deploy key**。PAT は同期のたびにパスワードを聞かれ、期限が切れると同期が止まる。
deploy key はこのリポジトリ1つにしか書き込めず、期限も無い。

1. **Termux を F-Droid 版で入れる**（Play ストア版は古く、`pkg` が通らない）

   ```sh
   pkg update && pkg upgrade
   pkg install git openssh
   termux-setup-storage          # 共有ストレージへのアクセスを許可する
   ```

2. 鍵を作り、自分の vault のリポジトリの deploy key に**書き込み可**で登録する

   ```sh
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   ssh-keygen -t ed25519 -N "" -C "android-vault-deploy" -f ~/.ssh/vault_deploy
   cat >> ~/.ssh/config <<'CONF'
   Host github.com
     IdentityFile ~/.ssh/vault_deploy
     IdentitiesOnly yes
   CONF
   chmod 600 ~/.ssh/config
   cat ~/.ssh/vault_deploy.pub   # → GitHub の Settings → Deploy keys（Allow write access）
   ```

   パスフレーズは付けない（毎回聞かれる）。鍵は Termux のホーム（アプリ専有領域）にあり、vault の外なので同期対象に入らない。

3. clone の前に設定を入れる。**上の3つはこのリポジトリの事情**なので省略できない

   ```sh
   git config --global core.symlinks false   # AGENTS.md が CLAUDE.md への symlink。共有ストレージは symlink を作れない
   git config --global core.fileMode false   # 共有ストレージは権限ビットが素直に扱えない
   git config --global --add safe.directory /storage/emulated/0/Documents/vault
                                             # 共有ストレージのファイルはメディア用 uid の持ち物に見え、git が拒否する
   git config --global user.name  "<名前>"
   git config --global user.email "<メールアドレス>"
   git config --global commit.gpgsign false  # スマホに署名鍵は置かない
   git config --global core.pager cat        # Termux には git の既定の pager が無い
   ```

4. `~/storage/shared/Documents` に clone し、Obsidian の「フォルダを保管庫として開く」で `Documents/vault` を選ぶ。
   どのプラグインを有効にするかは端末ごとの設定（`community-plugins.json` は追跡しない）なので、**QuickAdd はここで手で有効化する**

## 同期スクリプト

**共有ストレージのファイルは実行できない**ので、スクリプトは Termux のホーム側に置く。正本は `vault-sync.sh`（このフォルダ）で、端末にあるのはその写し。

```sh
mkdir -p ~/.shortcuts && chmod 700 ~/.shortcuts
cp ~/storage/shared/Documents/vault/integrations/android/vault-sync.sh ~/.shortcuts/
chmod +x ~/.shortcuts/vault-sync.sh
```

`~/.shortcuts` に置くと **Termux:Widget**（F-Droid）からホーム画面のボタンで叩ける。

- `git pull --rebase --autostash` — merge にすると中身のないマージコミットが捕獲のたびに積まれる。捕獲直後は未コミットの変更があるので autostash が要る
- `git commit -- 0-Inbox/quick.md` — index を経由せず、そのパスだけをコミットする。他のファイルをスマホで触っても push されない

## 運用

「Obsidian で捕獲 → ウィジェットで sync」。起動時の自動 pull は無いので、捕獲の前にも一度 sync しておくと安全。
競合したらスマホでは解決せず（`git rebase --abort` で戻す）、デスクトップで両方の行を残す。
モバイル由来のコミットには署名が付かない（GitHub 上で `Unverified`）が、異常ではない。
