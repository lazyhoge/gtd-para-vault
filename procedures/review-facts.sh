#!/usr/bin/env bash
# 週次レビューの下ごしらえに使う事実を、1回で Markdown に出す。判断（案）は含めない。
# 使い方: nix shell nixpkgs#yq-go nixpkgs#jq nixpkgs#taskwarrior3 -c bash ~/vault/procedures/review-facts.sh
#   SINCE: 「見積もりと実績」で数える完了の始まり（既定: 7日前の今。YYYY-MM-DDTHH:MM:SS、日本時間）
#   VAULT: 対象の vault（既定 ~/vault）
# 出す事実（procedures/weekly-review.md の節の順）:
#   0-Inbox の残り / 止まっている Project / 期限切れ・7日以内が期限 / 7日以上動いていない連絡待ち /
#   見積もりと実績 / 期限の無い Project / Area の基準 / いつか / 進行中の Project が無い目標 /
#   未検証の知識 / stale_after を過ぎた知識 / 次の行動の緊急度
# 緊急度は Taskwarrior に計算させる（既定の係数。views/next-actions.base の式はその写しで、表示用）
# 入力は procedures/vault-query.sh json（frontmatter の JSON）。依存: yq（yq-go）・jq・task（taskwarrior3）
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export VAULT=${VAULT:-$HOME/vault}
cd "$VAULT"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
now=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M:%S)
since=${SINCE:-$(TZ=Asia/Tokyo date -d '7 days ago' +%Y-%m-%dT%H:%M:%S)}
week_ago=$(TZ=Asia/Tokyo date -d '7 days ago' +%Y-%m-%dT%H:%M:%S)
in7=$(TZ=Asia/Tokyo date -d '7 days' +%Y-%m-%d)

bash "$here/vault-query.sh" json > "$work/all.json"

# 緊急度: 一時ディレクトリの Taskwarrior に入れて計算させ、uuid → urgency にする。
# 繰り返しの回は作らせない（recurrence=off）。正本は Markdown なので、Taskwarrior に状態を残さない
cat > "$work/rc" <<EOF
data.location=$work/data
confirmation=off
verbose=nothing
recurrence=off
uda.estimate.type=numeric
uda.actual.type=numeric
uda.intervals.type=string
uda.waiting_on.type=string
EOF
export TASKRC=$work/rc
bash "$here/export-taskwarrior.sh" > "$work/in.json"
task import "$work/in.json" >/dev/null
task export | jq 'map({key: .uuid, value: .urgency}) | from_entries' > "$work/urgency.json"

# 0-Inbox の残り: quick.md の追記欄の行と、日付のフォルダの中のファイル
quick=$(awk 'f && NF; /<!-- ここから下に追記 -->/ {f = 1}' 0-Inbox/quick.md)
captures=$(find 0-Inbox -mindepth 2 -type f -name '*.md' ! -name index.md | sort)

{
  echo "# 週次レビューの事実（$now 時点）"
  echo
  echo "<!-- procedures/review-facts.sh の出力。判断は含まない -->"
  echo
  echo "## 0-Inbox の残り"
  echo
  echo "- quick.md: $(printf '%s' "$quick" | grep -c . || true) 行"
  printf '%s\n' "$quick" | grep . | sed 's/^- */  - /' || true
  echo "- 日付のフォルダ: $(printf '%s' "$captures" | grep -c . || true) 件"
  printf '%s\n' "$captures" | grep . | sed 's/^/  - /' || true
  echo
  jq -r --slurpfile urg "$work/urgency.json" --arg now "$now" --arg since "$since" \
    --arg week_ago "$week_ago" --arg today "${now:0:10}" --arg in7 "$in7" '
    def link: if type == "string" then sub("^\\[\\["; "") | sub("\\]\\]$"; "") | sub("\\|.*$"; "") else "" end;
    def name: ._path | sub("^.*/"; "") | sub("\\.md$"; "");
    def has($t): ((.tags // []) | index($t)) != null;
    def blank: if . == null or . == "" or . == [] then "-" else tostring end;
    def item: "- [[\(name)]] \(.description // .title // "" | gsub("\n"; " "))";
    def none: if length == 0 then "- なし" else .[] end;
    def ymd: tostring | .[0:10];
    def section($title; lines): "## \($title)", "", ([lines] | none), "";

    $urg[0] as $urg
    | (map(select(.type == "task"))) as $tasks
    | (map(select(.type == "project"))) as $projects
    | ($projects | map({key: name, value: (.parent | link)}) | from_entries) as $pparent
    # タスクがその Project（または子の Project）に属するか
    | def in_project($p): (.project | link) as $q | $q == $p or $pparent[$q] == $p;

    section("止まっている Project（active で、next の付いた pending のタスクが無い）";
      $projects[] | select(.status == "active") | name as $p
      | select([$tasks[] | select(.status == "pending" and has("next") and in_project($p))] | length == 0)
      | item + "（pending \([$tasks[] | select(.status == "pending" and in_project($p))] | length) 件）"),

    ([.[] | select(.type == "task" and .status == "pending" and (.parent // "") != "" and (.due // "") != "" and (.due | ymd) <= $in7)] | length) as $nrecur
    | section("期限切れ・7日以内が期限（\($in7) まで。繰り返しの回 \($nrecur) 件は除く）";
      [.[] | select((.parent // "") == "") | select((.type == "task" and .status == "pending") or (.type == "project" and .status == "active")
                    or (.type == "goal" and .status == "active"))
           | select((.due // "") != "" and (.due | ymd) <= $in7)]
      | sort_by(.due | tostring) | .[]
      | item + "（\(.type)、due \(.due)\(if (.due | ymd) < $today then "、期限切れ" else "" end)）"),

    section("連絡待ちで7日以上動いていないもの（modified が \($week_ago[0:10]) より前）";
      $tasks[] | select(.status == "pending" and has("waiting") and ((.modified // "") | tostring) < $week_ago)
      | item + "（相手 \(.waiting_on | blank)、modified \(.modified)）"),

    ([$tasks[] | select(.status == "completed" and ((.end // "") | tostring) >= $since)] | sort_by(.end)) as $done
    | ([$done[] | select(.estimate != null and (.actual // 0) > 0)]) as $pair
    | ([$pair[] | .estimate] | add // 0) as $est
    | ([$pair[] | .actual] | add // 0) as $act
    | "## 見積もりと実績（\($since) 以降に完了）", "",
      "- 完了 \($done | length) 件。見積もりと実績の両方がある \($pair | length) 件で、見積 \($est) 分・実績 \($act) 分・比率 \(if $est > 0 then ($act / $est * 100 | round / 100) else "-" end)",
      "- 比率から除いたもの: 見積もりが無い \([$done[] | select(.estimate == null)] | length) 件、実績が 0（区間の記録が無い）\([$done[] | select(.estimate != null and (.actual // 0) == 0)] | length) 件",
      ($done[] | item + "（見積 \(.estimate | blank)・実績 \(.actual | blank)）"), "",

    section("期限の無い Project（active）";
      $projects[] | select(.status == "active" and (.due // "") == "") | item),

    section("Area の基準（standard を、定義の事実で判定する）";
      .[] | select(.type == "area" and .status == "active" and (.standard // "") != "")
      | "- [[\(name)]] \(.standard)"),

    section("いつか（someday の Project とタスク）";
      ($projects[] | select(.status == "someday") | item + "（Project）"),
      ($tasks[] | select(.status == "pending" and has("someday")) | item)),

    section("進行中の Project が無い目標";
      .[] | select(.type == "goal" and .status == "active") | name as $g
      | select([$projects[] | select(.status == "active" and (.goal | link) == $g)] | length == 0) | item),

    section("未検証の知識（verified が無い。created の新しい順）";
      [.[] | select((.type == "note" or .type == "agent" or .type == "playbook") and (.verified // "") == ""
                    and ((._path | startswith("templates/")) | not))]
      | sort_by(.created | tostring) | reverse | .[] | item + "（\(._path | sub("/[^/]*$"; ""))、\(.created | blank)）"),

    section("stale_after を過ぎた知識";
      .[] | select((.stale_after // "") != "" and (.stale_after | tostring | .[0:19]) <= $now)
      | item + "（stale_after \(.stale_after)）"),

    "## 次の行動の緊急度（Taskwarrior の既定の係数。上位20件）", "",
    "| 緊急度 | タスク | priority | estimate | due | scheduled |", "|---|---|---|---|---|---|",
    ([$tasks[] | select(.status == "pending" and has("next") and (has("waiting") | not))
      | . + {urgency: ($urg[.uuid] // 0)}] | sort_by([-.urgency, (.estimate // 0)]) | .[0:20][]
     | "| \(.urgency * 10 | round / 10) | [[\(name)]] | \(.priority | blank) | \(.estimate | blank) | \(.due | blank) | \(.scheduled | blank) |")
  ' "$work/all.json"
}
