#!/usr/bin/env bash
# vault のタスク（type: task）を Taskwarrior の JSON（1行1タスク）に書き出す。
# 使い方: nix shell nixpkgs#yq-go nixpkgs#jq -c bash ~/vault/procedures/export-taskwarrior.sh > tasks.json
#   取り込み: task rc.uda.estimate.type=numeric rc.uda.actual.type=numeric \
#             rc.uda.intervals.type=string rc.uda.waiting_on.type=string import tasks.json
#   VAULT を指定すると、~/vault 以外（検証用の写しなど）から書き出す
# 変換（規約「行動: Taskwarrior 準拠」の4つの違い）:
#   - 日時: Obsidian の日時型（日本時間）→ YYYYMMDDTHHMMSSZ（UTC）。日付だけのものは、due はその日の
#     23:59:59（「その日のうち」の意味）、それ以外は 00:00（いずれも日本時間）
#   - project: [[slug]] → slug（親の Project があれば 親.子）
#   - depends: [[タスク名]] → そのタスクの uuid
#   - parent（繰り返しの親）: [[タスク名]] → そのタスクの uuid
set -euo pipefail
cd "${VAULT:-$HOME/vault}"
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
# 1. 全タスクと全 Project を1つの JSON 配列に集める（ファイル名を _file に入れる）
{
  for f in $(grep -rl --include='*.md' '^type: task$' 1-Projects 2-Areas 3-Resources 4-Archive 2>/dev/null); do
    yq --front-matter=extract -o=json ". + {\"_file\": \"$(basename "$f" .md)\"}" "$f"
  done
} | jq -s '.' > "$tmp"
projects=$(for f in $(grep -rl --include='*.md' '^type: project$' 1-Projects 4-Archive 2>/dev/null); do
  yq --front-matter=extract -o=json ". + {\"_file\": \"$(basename "$f" .md)\"}" "$f"; done | jq -s '.')
jq -c --argjson projects "$projects" '
  def link: if type == "string" then sub("^\\[\\["; "") | sub("\\]\\]$"; "") | sub("\\|.*$"; "") else . end;
  def utc(eod): if . == null or . == "" then null
           elif test("^\\d{4}-\\d{2}-\\d{2}$") then (. + (if eod then "T23:59:59" else "T00:00:00" end) | strptime("%Y-%m-%dT%H:%M:%S") | mktime - 32400 | strftime("%Y%m%dT%H%M%SZ"))
           else (sub("\\.\\d+$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime - 32400 | strftime("%Y%m%dT%H%M%SZ")) end;
  def utc: utc(false);
  ([.[] | {key: ._file, value: .uuid}] | from_entries) as $uuid
  | ($projects | map({key: ._file, value: (.parent | link)}) | from_entries) as $pparent
  | .[]
  | (.project | link) as $p
  | {
      uuid, status, description,
      entry: (.entry | utc), modified: (.modified | utc),
      scheduled: (.scheduled | utc), due: (.due | utc(true)), wait: (.wait | utc),
      start: (.start | utc), end: (.end | utc),
      project: (if $p == null or $p == "" then null
                elif ($pparent[$p] // "") != "" then ($pparent[$p] + "." + $p) else $p end),
      tags: (.tags // [] | if length == 0 then null else . end),
      priority,
      depends: ((.depends // []) | map(link | $uuid[.] // empty) | if length == 0 then null else join(",") end),
      annotations: ((.annotations // []) | map({entry: (.entry | tostring | utc), description}) | if length == 0 then null else . end),
      estimate, actual,
      intervals: ((.intervals // []) | if length == 0 then null else join(",") end),
      waiting_on,
      recur, until: (.until | utc), mask, imask,
      parent: (.parent | link | if . == null or . == "" then null else ($uuid[.] // null) end)
    }
  | with_entries(select(.value != null and .value != ""))
' "$tmp"
