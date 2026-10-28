#!/usr/bin/env bash
# タスクの actual を Project ごとに、Project を目標ごとに合計し、Project と目標の actual に書く。
# 週次レビューの下ごしらえで書き換えてよい唯一の状態（procedures/weekly-review.md の「集計」）。
# 使い方: bash ~/vault/procedures/sum-actuals.sh（依存: awk・yq（yq-go）・jq）
#   DRY_RUN=1: 書かずに、変わるものを表示する
#   VAULT: 対象の vault（既定 ~/vault）
# 出力: 値が変わった Project と目標を1行ずつ（パス・前の値・新しい値。daily のログに写す材料）
# 合計の範囲（status を問わず、完了・削除したタスクの実績も入れる）:
#   - Project: project がその Project のタスク ＋ parent がその Project の子の Project（再帰）
#   - 目標: goal がその目標の Project ＋ parent がその目標の子の目標（再帰）
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export VAULT=${VAULT:-$HOME/vault}
cd "$VAULT"

bash "$here/vault-query.sh" json | jq -r '
  def link: if type == "string" then sub("^\\[\\["; "") | sub("\\]\\]$"; "") | sub("\\|.*$"; "") else "" end;
  def name: ._path | sub("^.*/"; "") | sub("\\.md$"; "");
  . as $all
  | ($all | map(select(.type == "project"))) as $projects
  | ($all | map(select(.type == "goal"))) as $goals
  | def ptotal($p): ([$all[] | select(.type == "task" and (.project | link) == $p) | .actual // 0] | add // 0)
                    + ([$projects[] | select((.parent | link) == $p) | ptotal(name)] | add // 0);
    def gtotal($g): ([$projects[] | select((.goal | link) == $g) | ptotal(name)] | add // 0)
                    + ([$goals[] | select((.parent | link) == $g) | gtotal(name)] | add // 0);
  ($projects[] | {path: ._path, old: (.actual // 0), new: ptotal(name)}),
  ($goals[] | {path: ._path, old: (.actual // 0), new: gtotal(name)})
  | select(.old != .new) | [.path, .old, .new] | @tsv' |
while IFS=$'\t' read -r path old new; do
  echo "$path	$old → $new"
  [ -n "${DRY_RUN:-}" ] && continue
  # frontmatter の中の actual の行だけを書き換える（yq で書き戻すと他の行の書式が変わるため）
  awk -v v="$new" 'NR == 1 && /^---$/ { fm = 1; print; next }
                   fm && /^---$/ { fm = 0 }
                   fm && /^actual:/ { print "actual: " v; next }
                   { print }' "$path" > "$path.tmp" && mv "$path.tmp" "$path"
done
