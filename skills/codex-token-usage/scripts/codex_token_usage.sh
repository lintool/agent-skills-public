#!/usr/bin/env bash
set -euo pipefail

db="${CODEX_HOME:-$HOME/.codex}/state_5.sqlite"
codex_home="${CODEX_HOME:-$HOME/.codex}"
limit=20
graph_days=""
graph_hours=""
graph_weeks=""
graph_months=""

usage() {
  cat <<'EOF'
Usage: codex_token_usage.sh [--db PATH] [--limit N] [--graph-days N] [--graph-hours N] [--graph-weeks N|all] [--graph-months N|all]

Reports local Codex token usage from state_5.sqlite.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db)
      [[ $# -ge 2 ]] || { echo "--db requires a path" >&2; exit 2; }
      db="$2"
      shift 2
      ;;
    --limit)
      [[ $# -ge 2 ]] || { echo "--limit requires a number" >&2; exit 2; }
      limit="$2"
      shift 2
      ;;
    --graph-days)
      [[ $# -ge 2 ]] || { echo "--graph-days requires a number" >&2; exit 2; }
      graph_days="$2"
      shift 2
      ;;
    --graph-hours)
      [[ $# -ge 2 ]] || { echo "--graph-hours requires a number" >&2; exit 2; }
      graph_hours="$2"
      shift 2
      ;;
    --graph-weeks)
      [[ $# -ge 2 ]] || { echo "--graph-weeks requires a number or all" >&2; exit 2; }
      graph_weeks="$2"
      shift 2
      ;;
    --graph-months)
      [[ $# -ge 2 ]] || { echo "--graph-months requires a number or all" >&2; exit 2; }
      graph_months="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 is required" >&2
  exit 1
fi

if [[ ! -f "$db" ]]; then
  echo "Codex state database not found: $db" >&2
  exit 1
fi

if [[ ! "$limit" =~ ^[0-9]+$ ]]; then
  echo "--limit must be a non-negative integer" >&2
  exit 2
fi

if [[ -n "$graph_days" ]]; then
  if [[ ! "$graph_days" =~ ^[0-9]+$ || "$graph_days" -eq 0 ]]; then
    echo "--graph-days must be a positive integer" >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for actual daily token graphs" >&2
    exit 1
  fi

  sessions_dir="$codex_home/sessions"
  if [[ ! -d "$sessions_dir" ]]; then
    echo "Codex sessions directory not found: $sessions_dir" >&2
    exit 1
  fi

  python3 - "$sessions_dir" "$graph_days" <<'PY'
import datetime as dt
import json
import sys
from collections import defaultdict
from pathlib import Path

sessions_dir = Path(sys.argv[1])
days = int(sys.argv[2])

today = dt.datetime.now().astimezone().date()
start = today - dt.timedelta(days=days - 1)
rows = {start + dt.timedelta(days=i): 0 for i in range(days)}

for path in sorted(sessions_dir.rglob("*.jsonl")):
    previous_total = None
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("type") != "event_msg":
                continue
            payload = event.get("payload") or {}
            if payload.get("type") != "token_count":
                continue
            info = payload.get("info") or {}
            total_usage = info.get("total_token_usage") or {}
            total = total_usage.get("total_tokens")
            if not isinstance(total, int):
                continue
            timestamp = event.get("timestamp")
            if not timestamp:
                continue
            try:
                when = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00")).astimezone()
            except ValueError:
                continue
            delta = 0 if previous_total is None else total - previous_total
            previous_total = total
            if delta <= 0:
                continue
            day = when.date()
            if start <= day <= today:
                rows[day] += delta

max_tokens = max(rows.values(), default=0)
print("== daily token graph ==")
for day in sorted(rows):
    tokens = rows[day]
    if tokens == 0 or max_tokens == 0:
        bar = ""
    else:
        width = max(1, round(tokens * 40 / max_tokens))
        bar = "#" * width
    print(f"{day.isoformat()}  {tokens:12,}  {bar}")
PY
  exit 0
fi

if [[ -n "$graph_hours" ]]; then
  if [[ ! "$graph_hours" =~ ^[0-9]+$ || "$graph_hours" -eq 0 ]]; then
    echo "--graph-hours must be a positive integer" >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for actual hourly token graphs" >&2
    exit 1
  fi

  sessions_dir="$codex_home/sessions"
  if [[ ! -d "$sessions_dir" ]]; then
    echo "Codex sessions directory not found: $sessions_dir" >&2
    exit 1
  fi

  python3 - "$sessions_dir" "$graph_hours" <<'PY'
import datetime as dt
import json
import sys
from collections import defaultdict
from pathlib import Path

sessions_dir = Path(sys.argv[1])
days = int(sys.argv[2])

today = dt.datetime.now().astimezone().date()
start_day = today - dt.timedelta(days=days - 1)
local_tz = dt.datetime.now().astimezone().tzinfo
start = dt.datetime.combine(start_day, dt.time.min, tzinfo=local_tz)
end = dt.datetime.combine(today + dt.timedelta(days=1), dt.time.min, tzinfo=local_tz)
rows = defaultdict(int)

for path in sorted(sessions_dir.rglob("*.jsonl")):
    previous_total = None
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("type") != "event_msg":
                continue
            payload = event.get("payload") or {}
            if payload.get("type") != "token_count":
                continue
            info = payload.get("info") or {}
            total_usage = info.get("total_token_usage") or {}
            total = total_usage.get("total_tokens")
            if not isinstance(total, int):
                continue
            timestamp = event.get("timestamp")
            if not timestamp:
                continue
            try:
                when = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00")).astimezone()
            except ValueError:
                continue
            delta = 0 if previous_total is None else total - previous_total
            previous_total = total
            if delta <= 0:
                continue
            if start <= when < end:
                hour = when.replace(minute=0, second=0, microsecond=0)
                rows[hour] += delta

max_tokens = max(rows.values(), default=0)
print("== hourly token graph ==")
current = start
while current < end:
    tokens = rows.get(current, 0)
    if tokens:
        width = max(1, round(tokens * 40 / max_tokens)) if max_tokens else 0
        bar = "#" * width
        print(f"{current:%Y-%m-%d %H:00}  {tokens:12,}  {bar}")
    current += dt.timedelta(hours=1)
print(f"\ntotal {sum(rows.values()):,}")
PY
  exit 0
fi

if [[ -n "$graph_weeks" ]]; then
  if [[ "$graph_weeks" != "all" && ( ! "$graph_weeks" =~ ^[0-9]+$ || "$graph_weeks" -eq 0 ) ]]; then
    echo "--graph-weeks must be a positive integer or all" >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for actual weekly token graphs" >&2
    exit 1
  fi

  sessions_dir="$codex_home/sessions"
  if [[ ! -d "$sessions_dir" ]]; then
    echo "Codex sessions directory not found: $sessions_dir" >&2
    exit 1
  fi

  python3 - "$sessions_dir" "$graph_weeks" <<'PY'
import datetime as dt
import json
import sys
from collections import defaultdict
from pathlib import Path

sessions_dir = Path(sys.argv[1])
weeks_arg = sys.argv[2]
today = dt.datetime.now().astimezone().date()
start = None
if weeks_arg != "all":
    start = today - dt.timedelta(days=7 * int(weeks_arg) - 1)

rows = defaultdict(int)
spans = {}
for path in sorted(sessions_dir.rglob("*.jsonl")):
    previous_total = None
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("type") != "event_msg":
                continue
            payload = event.get("payload") or {}
            if payload.get("type") != "token_count":
                continue
            info = payload.get("info") or {}
            total_usage = info.get("total_token_usage") or {}
            total = total_usage.get("total_tokens")
            if not isinstance(total, int):
                continue
            timestamp = event.get("timestamp")
            if not timestamp:
                continue
            try:
                when = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00")).astimezone()
            except ValueError:
                continue
            delta = 0 if previous_total is None else total - previous_total
            previous_total = total
            if delta <= 0:
                continue
            day = when.date()
            if start and day < start:
                continue
            iso_year, iso_week, _ = day.isocalendar()
            key = f"{iso_year}-W{iso_week:02d}"
            rows[key] += delta
            week_start = day - dt.timedelta(days=day.weekday())
            week_end = week_start + dt.timedelta(days=6)
            if key not in spans:
                spans[key] = [week_start, week_end]

max_tokens = max(rows.values(), default=0)
print("== weekly token graph ==")
for key in sorted(rows, key=lambda k: spans[k][0]):
    tokens = rows[key]
    width = 0 if tokens == 0 or max_tokens == 0 else max(1, round(tokens * 40 / max_tokens))
    bar = "#" * width
    span = f"{spans[key][0].isoformat()}..{spans[key][1].isoformat()}"
    print(f"{key}  {span:<22}  {tokens:12,}  {bar}")
PY
  exit 0
fi

if [[ -n "$graph_months" ]]; then
  if [[ "$graph_months" != "all" && ( ! "$graph_months" =~ ^[0-9]+$ || "$graph_months" -eq 0 ) ]]; then
    echo "--graph-months must be a positive integer or all" >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for actual monthly token graphs" >&2
    exit 1
  fi

  sessions_dir="$codex_home/sessions"
  if [[ ! -d "$sessions_dir" ]]; then
    echo "Codex sessions directory not found: $sessions_dir" >&2
    exit 1
  fi

  python3 - "$sessions_dir" "$graph_months" <<'PY'
import calendar
import datetime as dt
import json
import sys
from collections import defaultdict
from pathlib import Path

sessions_dir = Path(sys.argv[1])
months_arg = sys.argv[2]
today = dt.datetime.now().astimezone().date()
start = None
if months_arg != "all":
    months = int(months_arg)
    month = today.month - months + 1
    year = today.year
    while month <= 0:
        month += 12
        year -= 1
    start = dt.date(year, month, 1)

rows = defaultdict(int)
spans = {}
for path in sorted(sessions_dir.rglob("*.jsonl")):
    previous_total = None
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("type") != "event_msg":
                continue
            payload = event.get("payload") or {}
            if payload.get("type") != "token_count":
                continue
            info = payload.get("info") or {}
            total_usage = info.get("total_token_usage") or {}
            total = total_usage.get("total_tokens")
            if not isinstance(total, int):
                continue
            timestamp = event.get("timestamp")
            if not timestamp:
                continue
            try:
                when = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00")).astimezone()
            except ValueError:
                continue
            delta = 0 if previous_total is None else total - previous_total
            previous_total = total
            if delta <= 0:
                continue
            day = when.date()
            if start and day < start:
                continue
            key = f"{day.year:04d}-{day.month:02d}"
            rows[key] += delta
            first = dt.date(day.year, day.month, 1)
            last = dt.date(day.year, day.month, calendar.monthrange(day.year, day.month)[1])
            if key not in spans:
                spans[key] = [first, last]

max_tokens = max(rows.values(), default=0)
print("== monthly token graph ==")
for key in sorted(rows):
    tokens = rows[key]
    width = 0 if tokens == 0 or max_tokens == 0 else max(1, round(tokens * 40 / max_tokens))
    bar = "#" * width
    span = f"{spans[key][0].isoformat()}..{spans[key][1].isoformat()}"
    print(f"{key}  {span:<22}  {tokens:12,}  {bar}")
PY
  exit 0
fi

echo "== totals =="
sqlite3 -noheader -separator $'\t' "$db" \
"select 'last_day' as window, count(*) as threads, printf('%,d', coalesce(sum(tokens_used), 0)) as tokens
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-1 day') as integer)
 union all
 select 'last_week', count(*), printf('%,d', coalesce(sum(tokens_used), 0))
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-7 day') as integer)
 union all
 select 'last_month', count(*), printf('%,d', coalesce(sum(tokens_used), 0))
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-1 month') as integer)
 union all
 select 'all_time', count(*), printf('%,d', coalesce(sum(tokens_used), 0))
 from threads
 where tokens_used > 0;" |
awk -F '\t' '
  BEGIN {
    windows[0] = "window"
    threads[0] = "threads"
    tokens[0] = "tokens"
    row_count = 0
  }
  {
    row_count++
    windows[row_count] = $1
    threads[row_count] = $2
    tokens[row_count] = $3
  }
  END {
    window_width = length(windows[0])
    threads_width = length(threads[0])
    tokens_width = length(tokens[0])
    for (i = 1; i <= row_count; i++) {
      if (length(windows[i]) > window_width) window_width = length(windows[i])
      if (length(threads[i]) > threads_width) threads_width = length(threads[i])
      if (length(tokens[i]) > tokens_width) tokens_width = length(tokens[i])
    }
    printf "%-*s  %*s  %*s\n", window_width, windows[0], threads_width, threads[0], tokens_width, tokens[0]
    printf "%-*s  %*s  %*s\n", window_width, dashes(window_width), threads_width, dashes(threads_width), tokens_width, dashes(tokens_width)
    for (i = 1; i <= row_count; i++) {
      printf "%-*s  %*s  %*s\n", window_width, windows[i], threads_width, threads[i], tokens_width, tokens[i]
    }
  }
  function dashes(width, out, i) {
    out = ""
    for (i = 0; i < width; i++) out = out "-"
    return out
  }
'

echo
echo "== recent threads =="
sqlite3 -header -column "$db" \
"select datetime(coalesce(updated_at_ms/1000, updated_at), 'unixepoch', 'localtime') as updated,
        printf('%,d', tokens_used) as tokens,
        coalesce(model, '') as model,
        substr(replace(replace(title, char(10), ' '), char(13), ' '), 1, 60) as title,
        cwd
 from threads
 where tokens_used > 0
 order by coalesce(updated_at_ms/1000, updated_at) desc
 limit $limit;"
