#!/data/data/com.termux/files/usr/bin/bash
# スマホ（Termux）から vault を同期する。書き込み面は 0-Inbox/quick.md だけ（→ README.md）
set -euo pipefail
cd ~/storage/shared/Documents/vault

# 競合が残っていたら進まない（スマホでは解決せず、デスクトップで両方の行を残す）
conflicted() {
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "競合がある: $(git diff --name-only --diff-filter=U)。デスクトップで解決する" >&2
    exit 1
  fi
}

conflicted
git pull --rebase --autostash
conflicted

# 書き込み面は 0-Inbox/quick.md だけ。index を経由せずそのパスだけをコミットする
if git diff --quiet -- 0-Inbox/quick.md; then
  echo "捕獲なし"
else
  git commit -q -m "capture(inbox): モバイルからの捕獲" -- 0-Inbox/quick.md
fi

git push

# 新規ノートでの捕獲など、スマホにしか無いファイルはコミットしないので名前だけ出す
untracked=$(git ls-files --others --exclude-standard)
[ -z "$untracked" ] || printf 'スマホにしか無いファイル（デスクトップへ移す）:\n%s\n' "$untracked"
echo "完了"
