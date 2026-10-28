#!/usr/bin/env bash
# vault のタスクと Project を frontmatter から引き、1タスク1行で出す。ノートを1本ずつ読まずに一覧を得るためのもの。
# 使い方: bash ~/vault/procedures/vault-query.sh <サブコマンド> [絞り込み]（PATH にあれば lh-vault）
#   tasks [--project <slug>] [--area <slug>] [--all]   未完了（pending・waiting）のタスク
#   next  [--project <slug>] [--area <slug>]           next が付いた pending のタスクと、作業中（start あり）のタスク
#   project <slug> [--all]                             Project の定義と、中のタスク（子の Project の分も）
#   json                                               タスク・Project・目標・Area・知識の frontmatter を JSON 配列で出す（他のスクリプトの入力）
#   --project: その Project と子の Project のタスク
#   --area: 2-Areas/<slug>/ の単発のタスクと、area がその Area の Project のタスク
#   --all: someday のタグ・recurring の親（tasks）、completed・deleted（project）も出す
#   VAULT: 対象の vault（既定 ~/vault）
# 出力（タブ区切り。1行目は # で始まる見出し、空の項目は -）:
#   path  status  priority  tags  due  scheduled  start  description
#   並びは 作業中 → priority（H・M・L・無し）→ scheduled と due の早いほう → path
# 依存: awk・yq（yq-go）・jq
set -euo pipefail
self=$(realpath "$0")
cd "${VAULT:-$HOME/vault}"

usage() { sed -n '2,15p' "$self" | sed 's/^# \{0,1\}//' >&2; exit 2; }

cmd=${1:-}; [ -n "$cmd" ] || usage; shift
slug=""; project=""; area=""; all=false
if [ "$cmd" = project ]; then slug=${1:-}; [ -n "$slug" ] || usage; shift; fi
while [ $# -gt 0 ]; do
  case $1 in
    --project) project=${2:?}; shift 2 ;;
    --area) area=${2:?}; shift 2 ;;
    --all) all=true; shift ;;
    *) usage ;;
  esac
done

# タスク・Project・目標・Area・知識の frontmatter を、_path（vault からの相対パス）付きの JSON 配列にする。
# yq の --front-matter=extract は複数ファイルを渡すと2本目以降を読まないので、awk で frontmatter だけの
# YAML の束にしてから yq に1回で渡す
collect() {
  grep -rlE --include='*.md' '^type: (task|project|goal|area|note|agent|playbook)$' 1-Projects 2-Areas 3-Resources 4-Archive procedures 2>/dev/null \
    | sort | xargs awk '
        FNR == 1 { n = 0 }
        /^---$/ { n++; if (n == 1) { print "---"; print "_path: \"" FILENAME "\"" } ; next }
        n == 1 { print }' \
    | yq -o=json -I0 '.' | jq -s '.'
}

if [ "$cmd" = json ]; then collect; exit; fi
case $cmd in tasks|next|project) ;; *) usage ;; esac

now=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M:%S)
collect | jq -r --arg cmd "$cmd" --arg slug "$slug" --arg project "$project" --arg area "$area" \
  --argjson all "$all" --arg now "$now" '
  def link: if type == "string" then sub("^\\[\\["; "") | sub("\\]\\]$"; "") | sub("\\|.*$"; "") else "" end;
  def name: ._path | sub("^.*/"; "") | sub("\\.md$"; "");
  def blank: if . == null or . == "" or . == [] then "-" else . end;
  def short: if type == "string" then sub(":\\d{2}$"; "") else . end;
  def prank: {"H": 0, "M": 1, "L": 2}[.priority // ""] // 3;

  (map(select(.type == "project")) | map({key: name, value: .}) | from_entries) as $projects
  | (map(select(.type == "task"))) as $tasks
  # その Project か、親がその Project か
  | def in_project($p): (.project | link) as $q | $q == $p or (($projects[$q].parent // "") | link) == $p;
    def in_area($a): (._path | startswith("2-Areas/" + $a + "/"))
                     or ((($projects[.project | link].area // "") | link) == $a);
    def open: .status == "pending" or .status == "waiting";
    def row: [._path, .status, (.priority | blank), (.tags // [] | join(",") | blank),
              (.due | blank), (.scheduled | short | blank), (.start | short | blank), .description] | @tsv;
    def sorted: sort_by([(if (.start // "") != "" then 0 else 1 end), prank,
                         ([.scheduled, .due] | map(select(. != null and . != "")) | min // "9999"), ._path]);
    def header: ["# path", "status", "priority", "tags", "due", "scheduled", "start", "description"] | @tsv;

  if $cmd == "project" then
    ($projects[$slug] // ("Project が見つからない: \($slug)\n" | halt_error(1))) as $p
    | ([$tasks[] | select(in_project($slug))]) as $mine
    | "# project \($p._path)",
      "# status: \($p.status)  due: \($p.due | blank)  area: \($p.area | link | blank)  goal: \($p.goal | link | blank)  parent: \($p.parent | link | blank)",
      "# outcome: \($p.outcome | blank)",
      "# tasks: pending \([$mine[] | select(.status == "pending")] | length) / waiting \([$mine[] | select(.status == "waiting")] | length) / completed \([$mine[] | select(.status == "completed")] | length) / deleted \([$mine[] | select(.status == "deleted")] | length)",
      header,
      ($mine | map(select($all or open)) | sorted | .[] | row)
  else
    header,
    ($tasks
     | map(select(
         ($project == "" or in_project($project))
         and ($area == "" or in_area($area))
         and (if $cmd == "next" then
                .status == "pending" and (((.tags // []) | index("next")) != null or (.start // "") != "")
                and ((.wait // "") == "" or (.wait | tostring) <= $now)
              else
                open or ($all and .status == "recurring")
              end)
         and ($all or ((.tags // []) | index("someday")) == null)))
     | sorted | .[] | row)
  end'
