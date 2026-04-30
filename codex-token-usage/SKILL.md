---
name: codex-token-usage
description: Report local Codex token usage from the Codex state database and session JSONL files. Use when the user asks for a Codex token usage report, token count update, how many Codex tokens they have used recently, usage totals for the last day/week/month/all time, a graph of token count, ASCII bar charts, weekly summaries, summarize by week, monthly summaries, summarize monthly, per-thread token accounting, or usage grouped by time window/model.
---

# Codex Token Usage

Use the bundled script to query local Codex usage from `~/.codex/state_5.sqlite` and `~/.codex/sessions/**/*.jsonl`. Treat this as Codex client accounting, not final billing/accounting.

Hourly, daily, weekly, and monthly graphs use timestamped `token_count` events in session JSONL files. For each session, compute positive deltas between successive `total_token_usage.total_tokens` cumulative counters and assign each delta to the event's local hour, date, week, or month. This is the accurate daily-attribution view for token usage, including for sessions or threads that span multiple days. It is preferred over grouping the thread-level `threads.tokens_used` aggregate by `updated_at`, because `updated_at` can move an entire multi-day thread's aggregate total to the most recent day.

## Accounting Nuance

Codex stores token usage at two useful granularities:

- `state_5.sqlite` has one `threads.tokens_used` aggregate per thread, with `created_at` and `updated_at` timestamps.
- `sessions/**/*.jsonl` has timestamped `token_count` events emitted over the lifetime of a session.

The thread aggregate is useful for recent-thread tables and broad totals, but it is not a stable daily ledger. If a thread starts on Monday and is resumed on Tuesday, grouping `threads.tokens_used` by `updated_at` assigns the thread's entire accumulated total to Tuesday. Grouping by `created_at` has the opposite problem: Tuesday's resumed work stays attributed to Monday.

For hourly, daily, weekly, and monthly graphs, use session `token_count` events instead:

1. Read each session JSONL independently.
2. Track `total_token_usage.total_tokens` as a cumulative counter within that session.
3. Compute `delta = current_total - previous_total` for successive `token_count` events.
4. Ignore the first event in a session and any non-positive deltas, because they do not represent newly observed usage.
5. Attribute each positive delta to the event timestamp's local hour and date.
6. Roll the same hourly deltas up into days, ISO weeks, or months so hourly, daily, weekly, and monthly totals align.

When the user asks why graphs changed or how usage is counted across a thread spanning multiple days, explain this nuance: thread-level totals move with `updated_at`, but graph bars are daily-attributed from per-session cumulative token deltas at event time.

When the user asks for an hourly summary, use the same per-session delta accounting and bucket by local hour. If asked whether hourly and daily counts are consistent, verify or explain that summing all hourly buckets in a local day should equal that day's daily graph count, assuming both reports are generated from the same snapshot of session files.

## Rollup Consistency

Hourly, daily, weekly, and monthly graphs must all be views of the same session-event ledger. Compute token deltas once per session from timestamped `token_count` events, then roll those deltas up by local hour, local day, ISO week, or calendar month.

Expected invariants:

1. Hourly buckets within a local day sum to that day's daily bucket.
2. Daily buckets within an ISO week sum to that week's weekly bucket.
3. Daily buckets within a calendar month sum to that month's monthly bucket.
4. Across the full ledger, total hourly, daily, weekly, and monthly token counts are equal.

When verifying rollups, prefer completed periods or a single immutable snapshot of the session files. The current hour, current day, current ISO week, and current month can change while commands are running because active Codex sessions append new `token_count` events. If a mismatch only appears in the active bucket, rerun or exclude the current incomplete period before treating it as a bug.

## Quick Start

Run:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-days 14
```

The standard token usage report and token count update are the same output. For either phrase, first print a daily ASCII graph over the last 14 local calendar days:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-days 14
```

Then print the totals summary:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh
```

In the final answer, show the 14-day graph and only the `last_day`, `last_week`, `last_month`, and `all_time` summary from the totals output unless the user also asks for recent threads.

In this combined report, the graph and totals use different accounting views: graph buckets use session `token_count` deltas by local event time and are the correct per-day attribution; totals use thread-level `tokens_used` aggregates grouped by updated time and are broad window summaries rather than a daily ledger.

For explicit totals or recent-thread tables, run:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh
```

The totals mode prints:

- totals for `last_day`, `last_week`, `last_month`, and `all_time`
- the 20 most recently updated token-using threads

Use an explicit database path if needed:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --db /path/to/state_5.sqlite
```

Use a larger recent-thread table:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --limit 50
```

Print an ASCII daily graph:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-days 14
```

Print an ASCII hourly graph:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-hours 7
```

Print an ASCII weekly graph:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-weeks all
```

Print an ASCII monthly graph:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-months all
```

## Workflow

1. Prefer the bundled script for normal requests.
2. If the script fails because `sqlite3` is unavailable, say that local SQLite access is required.
3. If `~/.codex/state_5.sqlite` is missing, check whether `CODEX_HOME` is set and try `$CODEX_HOME/state_5.sqlite`.
4. When the user asks for a "token usage report", "token count update", or just "report", run `--graph-days 14` first, then run totals mode. Show the 14-day daily graph followed by a fixed-width compact summary containing `last_day`, `last_week`, `last_month`, and `all_time`, with numeric columns right-aligned. Do not include the recent-thread table from totals mode unless the user asks for it.
5. If the user asks only for a graph and provides no time range, use `--graph-days 14` by default.
6. When the user asks for a "graph of token count", provide an ASCII graph with one row per day. Use the bundled script's `--graph-days N` mode; default to 14 days if the user does not specify a range. These daily graphs should use session `token_count` deltas, not thread `updated_at` totals.
7. When the user asks to summarize by hour, provide an ASCII bar chart with one row per nonzero local hour. Use the bundled script's `--graph-hours N` mode; default to 7 days if the user does not specify a range.
8. When the user asks to "summarize by week", provide an ASCII bar chart with one row per week. Use `--graph-weeks all` unless the user gives a narrower range. Weekly graphs should use session `token_count` deltas aggregated by local ISO week.
9. When the user asks to "summarize monthly" or "summarize by month", provide an ASCII bar chart with one row per month. Use `--graph-months all` unless the user gives a narrower range. Monthly graphs should use session `token_count` deltas aggregated by local month.
10. Mention that graph buckets use session event timestamps in local time when relevant.
11. Mention that timestamps are rendered in local time.
12. When the user explicitly asks for totals, counts for last day/week/month/all time, recent threads, or per-thread usage, run the script without graph flags or with `--limit N`.
13. If the user asks how the accounting works or why graph values differ from thread totals, explain the accounting nuance above.

## Direct Queries

These direct queries are for ad hoc debugging. For user-facing formatted output, prefer the bundled script because it handles comma formatting and column alignment.

Recent threads:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite \
"select datetime(coalesce(updated_at_ms/1000, updated_at), 'unixepoch', 'localtime') as updated,
        tokens_used,
        model,
        substr(title,1,60) as title,
        cwd
 from threads
 where tokens_used > 0
 order by coalesce(updated_at_ms/1000, updated_at) desc
 limit 20;"
```

Window totals:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite \
"select 'last_day' as window, count(*) as threads, sum(tokens_used) as tokens
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-1 day') as integer)
 union all
 select 'last_week', count(*), sum(tokens_used)
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-7 day') as integer)
 union all
 select 'last_month', count(*), sum(tokens_used)
 from threads
 where tokens_used > 0
   and coalesce(updated_at_ms/1000, updated_at) >= cast(strftime('%s','now','-1 month') as integer)
 union all
 select 'all_time', count(*), sum(tokens_used)
 from threads
 where tokens_used > 0;"
```
