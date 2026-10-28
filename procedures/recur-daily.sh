#!/usr/bin/env bash
# 繰り返しのタスクを毎朝手入れする。定時実行（process:recur-timer。integrations/nix の lh-recur とそのタイマー）から呼ぶ。
# 使い方: nix shell nixpkgs#yq-go nixpkgs#jq nixpkgs#taskwarrior3 -c bash ~/vault/procedures/recur-daily.sh
#   DRY_RUN=1: 書かずに、やることを表示する（generate-recurring.sh にも渡る）
#   NO_COMMIT=1: daily への記録まではして、commit しない（検証用）
#   VAULT: 対象の vault（既定 ~/vault。検証用の写しに流すときに使う）
# やること:
#   1. 前の日までに予定されていた未完了の回を deleted にする（plan-day.md の手順 3 のうち、前の日までの分）。
#      回の日は scheduled、無ければ due の日付。作業中（start あり）の回は触らない
#   2. 前の月までの終わった回（completed・deleted）を 4-Archive/recurring/YYYY-MM/ へ移す（月は回の due の月）
#   3. generate-recurring.sh で次の回を作り、親の mask を直す
#   4. 変えたことを daily/{今日}.md のログに書き（無ければ雛形から作る）、変えたファイルだけをローカルに commit する
#      （push しない。git commit -- <paths> なので、本人がステージした変更は混ぜない）
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export VAULT=${VAULT:-$HOME/vault}
cd "$VAULT"
now=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M:%S); today=${now%%T*}; month=${today%-*}; hm=${now:11:5}
dry=${DRY_RUN:-}
who='定時実行 recur-timer が記録'
expired='完了の申告が無いまま予定の日を過ぎた（毎朝の定時実行で削除）'
changed=(); log=()
name() { basename "$1" .md; }
fm() { yq --front-matter=extract "$1 // \"\"" "$2"; }

# 回（parent を持つ type: task）。4-Archive にあるものは対象にしない
occurrences() {
  grep -rl --include='*.md' '^parent: "\[\[' 1-Projects 2-Areas 3-Resources 2>/dev/null | sort | while read -r f; do
    [ "$(fm .type "$f")" = task ] && echo "$f"
  done
}
mapfile -t occ < <(occurrences)

# 1. 前の日までの未完了の回を deleted にする
for f in "${occ[@]}"; do
  [ "$(fm .status "$f")" = pending ] && [ -z "$(fm .start "$f")" ] || continue
  day=$(fm .scheduled "$f"); [ -n "$day" ] || day=$(fm .due "$f"); day=${day%%T*}
  [ -n "$day" ] && [[ $day < $today ]] || continue
  if [ -n "$dry" ]; then echo "削除する: $f（$day の回）"; continue; fi
  now=$now expired=$expired yq --front-matter=process -i '
    .status = "deleted" | .end = (strenv(now) | from_yaml) | .modified = (strenv(now) | from_yaml)
    | .annotations += [{"entry": (strenv(now) | from_yaml), "description": strenv(expired)}] | .annotations[-1] style="flow"
  ' "$f"
  changed+=("$f"); log+=("- $hm [[$(name "$f")]]（$day の回）を削除した。完了の申告が無いまま日を過ぎた（$who）")
done

# 2. 前の月までの終わった回を 4-Archive/recurring/YYYY-MM/ へ移す
declare -A moved
for f in "${occ[@]}"; do
  case $(fm .status "$f") in completed|deleted) ;; *) continue ;; esac
  m=$(fm .due "$f"); m=${m:0:7}
  [ -n "$m" ] && [[ $m < $month ]] || continue
  dest=4-Archive/recurring/$m/$(basename "$f")
  if [ -n "$dry" ]; then echo "移す: $f → $dest"; continue; fi
  mkdir -p "$(dirname "$dest")"; mv "$f" "$dest"
  changed+=("$f" "$dest"); moved[$m]=$(( ${moved[$m]:-0} + 1 ))
done
for m in "${!moved[@]}"; do
  log+=("- $hm 終わった繰り返しの回 ${moved[$m]} 本を \`4-Archive/recurring/$m/\` へ移した（$who）")
done

# 3. 次の回を作り、親の mask を直す
gen=$(bash "$here/generate-recurring.sh")
if [ -n "$dry" ]; then [ -z "$gen" ] || echo "$gen"; exit 0; fi
parents=()
while read -r line; do
  [ -n "$line" ] || continue
  f=${line#*: }; f=${f%%（*}
  changed+=("$f")
  case $line in
    作った:*) log+=("- $hm [[$(name "$f")]] を作った（$who）") ;;
    回を直した:*) log+=("- $hm [[$(name "$f")]] を until 切れで削除した（$who）") ;;
    親を直した:*) parents+=("[[$(name "$f")]]") ;;
  esac
done <<<"$gen"
[ ${#parents[@]} -eq 0 ] || log+=("- $hm 繰り返しの親 ${#parents[@]} 個の mask を直した: $(IFS=・; echo "${parents[*]}")（$who）")

[ ${#log[@]} -gt 0 ] || { echo "変えたものは無い"; exit 0; }

# 4. daily に書き、変えたファイルだけを commit する
daily=daily/$today.md
[ -e "$daily" ] || sed "s/{{date:YYYY-MM-DD}}/$today/g" templates/daily.md > "$daily"
changed+=("$daily")
block=$(printf '%s\n' "${log[@]}") awk '/^## 🌙 EOD/ && !done { print ENVIRON["block"]; print ""; done = 1 } { print }' \
  "$daily" > "$daily.tmp" && mv "$daily.tmp" "$daily"
printf '%s\n' "${log[@]}"

[ -z "${NO_COMMIT:-}" ] || exit 0
for f in "${changed[@]}"; do
  [ -e "$f" ] && ! git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 && git add -N -- "$f"
done
git commit -q -m "recur: 毎朝の手入れ（$today）" -- "${changed[@]}"
