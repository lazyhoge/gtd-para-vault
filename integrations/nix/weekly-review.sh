# 週次レビューの下ごしらえを、Claude Code を非対話で起動して作る（~/vault/procedures/weekly-review.md）。
# 暫定の仕組み。実行基盤（Hermes など）を採用したら外す。
# LH_VAULT_DIR はラッパの先頭で export される。

week=$(date +%G-W%V)
out="$LH_VAULT_DIR/daily/$week.md"

if [ -e "$out" ]; then
  echo "$week の週次レビューはすでにある: $out"
  exit 0
fi

cd "$LH_VAULT_DIR"

prompt="あなたは定時の非対話の実行（process:weekly-review-timer）から起動された。
~/vault/procedures/weekly-review.md を読み、その「定時で動くときの制約」に従って下ごしらえだけを行う。
対象の週は $week、書き出し先は daily/$week.md。本人には質問できないので、判断が要るものはすべて案として書き残す。
終わったら、変えたファイルだけをローカルにコミットする（push しない）。新しく作ったファイル（daily/$week.md など）は、
git commit -- <paths> が未追跡のファイルを受け付けないので、先に git add -N <path> してから git commit -- <paths> する。
コミットに失敗したら（署名鍵が agent に無いなど）、未コミットのまま残して、そのことを最後の1行に書く。"

if claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read Glob Grep Write Edit Bash(git status*) Bash(git diff*) Bash(git log*) Bash(git add -N*) Bash(git commit*) Bash(date*) Bash(nix shell nixpkgs#yq-go*) Bash(wc -c*) Bash(systemctl list-units --failed*) Bash(systemctl --user list-units --failed*)" \
    > "${XDG_CACHE_HOME:-$HOME/.cache}/lh-weekly-review.log" 2>&1; then
  notify-send -a "週次レビュー" "週次レビューの下ごしらえができた" "$(tail -n 1 "${XDG_CACHE_HOME:-$HOME/.cache}/lh-weekly-review.log")" \
    || echo "通知を出せなかった（下ごしらえ自体はできている）" >&2
else
  notify-send -u critical -a "週次レビュー" "週次レビューの下ごしらえに失敗した" "ログ: ~/.cache/lh-weekly-review.log" \
    || echo "失敗の通知を出せなかった" >&2
  exit 1
fi
