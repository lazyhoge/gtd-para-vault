#!/usr/bin/env bash
# 繰り返しのタスク（status: recurring の親）から次の回を生成し、Markdown に書き戻す。
# 使い方: nix shell nixpkgs#yq-go nixpkgs#jq nixpkgs#taskwarrior3 -c bash ~/vault/procedures/generate-recurring.sh
#   RECUR_LIMIT: 先に作っておく回の数（Taskwarrior の recurrence.limit。既定 1）
#   DRY_RUN=1: 書かずに、作る回と直すタスクを表示する
#   VAULT: 対象の vault（既定 ~/vault。検証用の写しに流すときに使う）
# 出力: 作った回と直したタスクを1行ずつ（daily のログに写す材料）
# 方式（規約「行動: Taskwarrior 準拠」の繰り返し）:
#   1. vault の全タスクを export-taskwarrior.sh で書き出し、一時ディレクトリの Taskwarrior に import する
#   2. task list で回を生成させる。一時ディレクトリは最後に消す（正本は Markdown で、Taskwarrior に状態を残さない）
#   3. 新しい回を、親のファイルを写して <親>-YYYY-MM-DD.md として親と同じフォルダに書く。
#      Taskwarrior から取るのは uuid・imask・due・entry・status・end だけで、他の項目と本文は親のまま。
#      scheduled と wait は Taskwarrior がずらさないので、親の値 + (回の due − 親の due) で計算し直す
#   4. 既存の回のうち、Taskwarrior が status を変えたもの（until を過ぎて deleted になった回）を書き戻す
#   5. 親の mask を回の status から計算し直す（- pending / + completed / X deleted / W waiting）。
#      until を過ぎた親は completed にする
# Taskwarrior 3.4.2 の振る舞いで合わせたもの（2026-10-01 に確かめた）:
#   - until は「過ぎたら deleted にする」期限として働き、回にも写る
#   - until より後の due の回も作ることがある → 作らない（RFC の「until の後は生成しない」に合わせる）
#   - 回を自動で deleted にしても親の mask は直さない → 5 で直す
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export VAULT=${VAULT:-$HOME/vault}
cd "$VAULT"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
now=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M:%S)
dry=${DRY_RUN:-}

# 1. 一時ディレクトリの Taskwarrior に、vault の全タスクを入れる
cat > "$work/rc" <<EOF
data.location=$work/data
confirmation=off
verbose=nothing
recurrence=on
recurrence.limit=${RECUR_LIMIT:-1}
uda.estimate.type=numeric
uda.actual.type=numeric
uda.intervals.type=string
uda.waiting_on.type=string
EOF
export TASKRC=$work/rc
bash "$here/export-taskwarrior.sh" > "$work/in.json"
task import "$work/in.json" >/dev/null

# 2. 回を生成させる（該当が無いと終了コードが 1 になるので無視する）
task list >/dev/null 2>&1 || true
task export > "$work/out.json"

# 繰り返しに関わるタスク（recur を持つもの）の uuid → ファイルのパス
declare -A path
for f in $(grep -rl --include='*.md' '^recur: ' 1-Projects 2-Areas 3-Resources 4-Archive 2>/dev/null); do
  [ "$(yq --front-matter=extract '.type' "$f")" = task ] || continue
  path[$(yq --front-matter=extract '.uuid' "$f")]=$f
done

jst='strptime("%Y%m%dT%H%M%SZ") | mktime + 32400 | strftime("%Y-%m-%dT%H:%M:%S")'
epoch='strptime("%Y%m%dT%H%M%SZ") | mktime'
expired='until を過ぎたので削除した（Taskwarrior の until の扱い）'

# 日時を delta 秒ずらす。日付だけの値は日付だけで返す（export-taskwarrior.sh の変換の逆）
shift_dt() {
  local v=$1 delta=$2 fmt=%Y-%m-%dT%H:%M:%S
  if [ -z "$v" ] || [ "$v" = null ]; then echo ""; return; fi
  [[ $v =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && fmt=%Y-%m-%d
  TZ=Asia/Tokyo date -d "@$(( $(TZ=Asia/Tokyo date -d "$v" +%s) + delta ))" +$fmt
}

# 3. 新しい回を書く（until より後の due の回は作らない）
jq -c --slurpfile in "$work/in.json" '
  ($in | map({key: .uuid, value: .}) | from_entries) as $before
  | .[] | select(($before[.uuid] | not) and .parent != null)
  | ($before[.parent]) as $p
  | select(($p.until == null) or ((.due | '"$epoch"') <= ($p.until | '"$epoch"')))
  | {uuid, imask, status, entry: (.entry | '"$jst"'), due: (.due | '"$jst"'),
     end: (if .end then .end | '"$jst"' else "" end),
     delta: ((.due | '"$epoch"') - ($p.due | '"$epoch"')), parent}
' "$work/out.json" | while read -r c; do
  eval "$(jq -r '@sh "uuid=\(.uuid) imask=\(.imask) st=\(.status) entry=\(.entry) due=\(.due) end=\(.end) delta=\(.delta) pu=\(.parent)"' <<<"$c")"
  pf=${path[$pu]:-}
  [ -n "$pf" ] || { echo "親が見つからない: $pu" >&2; exit 1; }
  [[ $(yq --front-matter=extract '.due' "$pf") =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && due=${due%%T*}
  sch=$(shift_dt "$(yq --front-matter=extract '.scheduled // ""' "$pf")" "$delta")
  wt=$(shift_dt "$(yq --front-matter=extract '.wait // ""' "$pf")" "$delta")
  base=$(basename "$pf" .md); dir=$(dirname "$pf")
  out="$dir/$base-${due%%T*}.md"
  [ -e "$out" ] && out="$dir/$base-${due%%T*}-$(TZ=Asia/Tokyo date -d "$due" +%H%M).md"
  if [ -n "$dry" ]; then echo "作る: $out（$st, due $due${sch:+, scheduled $sch}）"; continue; fi
  expr='.uuid = strenv(uuid) | .status = strenv(st) | .entry = (strenv(entry) | from_yaml) | .modified = (strenv(entry) | from_yaml)
    | .due = (strenv(due) | from_yaml) | del(.mask) | .parent = strenv(parent) | .parent style="double"
    | .imask = (strenv(imask) | from_yaml)'
  [ -n "$sch" ] && expr+=' | .scheduled = (strenv(sch) | from_yaml)'
  [ -n "$wt" ] && expr+=' | .wait = (strenv(wt) | from_yaml)'
  [ -n "$end" ] && expr+=' | .end = (strenv(end) | from_yaml) | .annotations += [{"entry": (strenv(now) | from_yaml), "description": strenv(expired)}] | .annotations[-1] style="flow"'
  uuid=$uuid st=$st entry=$entry due=$due sch=$sch wt=$wt end=$end imask=$imask parent="[[$base]]" now=$now expired=$expired \
    yq --front-matter=process "$expr" "$pf" > "$out"
  echo "作った: $out（$st）"
done

# 4. 既存の回のうち、Taskwarrior が status を変えたものを書き戻す
jq -c --slurpfile in "$work/in.json" '
  ($in | map({key: .uuid, value: .status}) | from_entries) as $before
  | .[] | select(.parent != null and $before[.uuid] != null and $before[.uuid] != .status)
  | {uuid, status, end: (if .end then .end | '"$jst"' else "" end)}
' "$work/out.json" | while read -r c; do
  eval "$(jq -r '@sh "uuid=\(.uuid) st=\(.status) end=\(.end)"' <<<"$c")"
  f=${path[$uuid]:-}; [ -n "$f" ] || continue
  if [ -n "$dry" ]; then echo "回を直す: $f（→ $st）"; continue; fi
  st=$st end=$end now=$now expired=$expired yq --front-matter=process -i '
    .status = strenv(st) | .modified = (strenv(now) | from_yaml) | .end = (strenv(end) | from_yaml)
    | .annotations += [{"entry": (strenv(now) | from_yaml), "description": strenv(expired)}] | .annotations[-1] style="flow"
  ' "$f"
  echo "回を直した: $f（$st）"
done

# 5. 親の mask と status を直す。回の status は、作らなかった回も含めて Taskwarrior の出力から取る
jq -c --arg now "$now" '
  (map(select(.parent != null)) | group_by(.parent) | map({key: .[0].parent, value: .}) | from_entries) as $kids
  | .[] | select(.recur != null and .parent == null)
  | . as $p
  | {uuid,
     mask: (reduce ($kids[$p.uuid] // [])[] as $k (($p.mask // "") | split("");
              .[$k.imask] = ({"pending": "-", "completed": "+", "deleted": "X", "waiting": "W"}[$k.status] // "-"))
            | map(. // "-") | join("")),
     expired: ($p.until != null and ($p.until | '"$jst"') < $now)}
' "$work/out.json" | while read -r p; do
  eval "$(jq -r '@sh "pu=\(.uuid) mask=\(.mask) expired=\(.expired)"' <<<"$p")"
  pf=${path[$pu]:-}; [ -n "$pf" ] || continue
  cur_mask=$(yq --front-matter=extract '.mask // ""' "$pf"); cur_st=$(yq --front-matter=extract '.status' "$pf")
  close=; [ "$expired" = true ] && [ "$cur_st" = recurring ] && close=1
  [ "$mask" = "$cur_mask" ] && [ -z "$close" ] && continue
  if [ -n "$dry" ]; then echo "親を直す: $pf（mask $cur_mask → $mask${close:+, completed}）"; continue; fi
  expr='.mask = strenv(mask) | .modified = (strenv(now) | from_yaml)'
  [ -n "$close" ] && expr+=' | .status = "completed" | .end = (strenv(now) | from_yaml)'
  mask=$mask now=$now yq --front-matter=process -i "$expr" "$pf"
  echo "親を直した: $pf（mask $mask${close:+, completed}）"
done
