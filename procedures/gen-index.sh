#!/usr/bin/env bash
# OKF の index.md を、各ファイルの frontmatter（type / title / description）から生成する。
# 使い方: nix shell nixpkgs#yq-go -c bash ~/vault/procedures/gen-index.sh（VAULT で対象を変えられる。ノートを足したり動かしたりしたら流し直す）
set -euo pipefail
cd "${VAULT:-$HOME/vault}"
label() { case "$1" in
  area) echo "エリアの定義";; goal) echo "目標";; project) echo "Project";; task) echo "タスク";;
  note) echo "知識";; agent) echo "エージェント";; playbook) echo "手順書";; *) echo "その他";; esac; }
gen_dir() {
  local d=$1 heading=$2 intro=${3:-}
  local out="$d/index.md"
  {
    echo "# $heading"
    echo
    if [ -n "$intro" ]; then echo "$intro"; echo; fi
    for t in area goal project task note agent playbook; do
      local rows=""
      for f in "$d"/*.md; do
        [ "$(basename "$f")" = index.md ] && continue
        [ -f "$f" ] || continue
        ty=$(yq --front-matter=extract '.type // ""' "$f")
        [ "$ty" = "$t" ] || continue
        ti=$(yq --front-matter=extract '.title // .description // ""' "$f")
        [ "$t" = task ] && ti=$(yq --front-matter=extract '.description // ""' "$f")
        de=$(yq --front-matter=extract '.description // ""' "$f")
        [ "$t" = task ] && de="$(yq --front-matter=extract '.status // ""' "$f") / priority $(yq --front-matter=extract '.priority // "-"' "$f")"
        rows+="* [$ti]($(basename "$f")) - $de"$'\n'
      done
      if [ -n "$rows" ]; then echo "## $(label $t)"; echo; printf '%s' "$rows"; echo; fi
    done
    local subs=""
    for s in "$d"/*/; do
      [ -d "$s" ] || continue
      n=$(basename "$s")
      def="$s$n.md"
      de=""
      [ -f "$def" ] && de=$(yq --front-matter=extract '.description // ""' "$def")
      subs+="* [$n]($n/) - $de"$'\n'
    done
    if [ -n "$subs" ]; then echo "## サブディレクトリ"; echo; printf '%s' "$subs"; echo; fi
  } | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$out"
}
for a in 2-Areas/*/; do a=${a%/}; n=$(basename "$a"); gen_dir "$a" "$(yq --front-matter=extract '.title' "$a/$n.md") ($n)"; done
[ -n "$(ls -d 1-Projects/*/ 2>/dev/null)" ] && for p in 1-Projects/*/; do p=${p%/}; n=$(basename "$p"); gen_dir "$p" "$(yq --front-matter=extract '.title' "$p/$n.md")"; done
gen_dir 2-Areas "Areas（責任の領域）"
[ -d 1-Projects ] && gen_dir 1-Projects "Projects（進行中の成果）"
gen_dir procedures "手順書"
gen_dir 3-Resources "Resources（参照）" "関心・参照だけの知識を置く。行動を伴わないもの。どの Area にも属さない参照はここに、トピックごとのフォルダで置く。"
gen_dir 4-Archive "Archive（完了・休止）" "完了・中止した Project と、休止した Area をフォルダごと移す。終わった繰り返しの回は recurring/YYYY-MM/ に月ごとに移す。中のタスクの実績は、一覧（views の done-log など）で引き続き集計される。"
