#!/usr/bin/env python3
import argparse
import datetime as dt
import json
from collections import defaultdict
from pathlib import Path


def fmt(value):
    return f"{value:,}"


def clean(text, width=86):
    return " ".join((text or "").split())[:width]


def session_metadata(path):
    cwd = ""
    title = ""
    session_id = path.stem.replace("rollout-", "")

    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            if event.get("type") == "session_meta":
                payload = event.get("payload") or {}
                cwd = payload.get("cwd") or cwd
                session_id = payload.get("id") or session_id

            payload = event.get("payload") or {}
            if payload.get("type") == "user_message" and payload.get("message") and not title:
                title = clean(payload.get("message"))
                break

            if event.get("type") == "response_item":
                item = event.get("payload") or {}
                if item.get("role") != "user" or title:
                    continue
                parts = []
                for content in item.get("content") or []:
                    if not isinstance(content, dict) or content.get("type") != "input_text":
                        continue
                    text = content.get("text") or ""
                    if text.startswith("# AGENTS.md") or text.startswith("<environment_context>"):
                        continue
                    parts.append(text)
                if parts:
                    title = clean(" ".join(parts))
                    break

    return session_id, cwd, title


def positive_component_deltas(current_components, previous_components, is_first_event):
    component_delta = {}
    for key, value in current_components.items():
        previous_value = (previous_components or {}).get(key)
        if is_first_event:
            component_delta[key] = value if isinstance(value, int) else 0
        elif isinstance(value, int) and isinstance(previous_value, int):
            component_delta[key] = value - previous_value
        else:
            component_delta[key] = 0
    return component_delta


def collect_daily_breakdown(target, session_roots):
    by_hour = defaultdict(int)
    by_cwd = defaultdict(int)
    by_session = {}
    components = defaultdict(int)

    for root in session_roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.jsonl")):
            previous_total = None
            previous_components = None
            row = None

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
                    usage = ((payload.get("info") or {}).get("total_token_usage") or {})
                    total = usage.get("total_tokens")
                    if not isinstance(total, int):
                        continue
                    timestamp = event.get("timestamp")
                    if not timestamp:
                        continue
                    try:
                        when = dt.datetime.fromisoformat(timestamp.replace("Z", "+00:00")).astimezone()
                    except ValueError:
                        continue

                    current_components = {
                        "input": usage.get("input_tokens"),
                        "cached": usage.get("cached_input_tokens"),
                        "output": usage.get("output_tokens"),
                        "reasoning": usage.get("reasoning_output_tokens"),
                    }
                    is_first_event = previous_total is None
                    delta = total if is_first_event else total - previous_total
                    component_delta = positive_component_deltas(
                        current_components,
                        previous_components,
                        is_first_event,
                    )

                    previous_total = total
                    previous_components = current_components

                    if delta <= 0 or when.date() != target:
                        continue

                    if row is None:
                        session_id, cwd, title = session_metadata(path)
                        row = by_session.setdefault(str(path), {
                            "session_id": session_id,
                            "cwd": cwd,
                            "title": title,
                            "tokens": 0,
                            "events": 0,
                            "first": when,
                            "last": when,
                            "input": 0,
                            "cached": 0,
                            "output": 0,
                            "reasoning": 0,
                        })

                    row["tokens"] += delta
                    row["events"] += 1
                    row["first"] = min(row["first"], when)
                    row["last"] = max(row["last"], when)

                    by_hour[when.replace(minute=0, second=0, microsecond=0)] += delta
                    by_cwd[row["cwd"]] += delta
                    for key, value in component_delta.items():
                        if value > 0:
                            row[key] += value
                            components[key] += value

    return by_hour, by_cwd, by_session, components


def print_daily_breakdown(target, by_hour, by_cwd, by_session, components):
    total = sum(by_hour.values())
    noncached_approx = components["input"] - components["cached"] + components["output"]

    print(f"== daily breakdown: {target.isoformat()} ==")
    print(f"total tokens:              {fmt(total)}")
    print(f"input tokens:              {fmt(components['input'])}")
    print(f"cached input tokens:       {fmt(components['cached'])}")
    print(f"output tokens:             {fmt(components['output'])}")
    print(f"reasoning output tokens:   {fmt(components['reasoning'])}")
    print(f"approx non-cached+output:  {fmt(noncached_approx)}")

    print("\n== by hour ==")
    for hour in sorted(by_hour):
        print(f"{hour:%Y-%m-%d %H:00}\t{fmt(by_hour[hour])}")

    print("\n== by workspace ==")
    for cwd, tokens in sorted(by_cwd.items(), key=lambda item: item[1], reverse=True):
        pct = (tokens / total * 100) if total else 0
        print(f"{fmt(tokens)}\t{pct:5.1f}%\t{cwd}")

    print("\n== by session ==")
    for row in sorted(by_session.values(), key=lambda item: item["tokens"], reverse=True):
        pct = (row["tokens"] / total * 100) if total else 0
        noncached = row["input"] - row["cached"] + row["output"]
        print("\t".join([
            fmt(row["tokens"]),
            f"{pct:5.1f}%",
            f"{row['first']:%H:%M}-{row['last']:%H:%M}",
            f"events={row['events']}",
            f"cached={fmt(row['cached'])}",
            f"noncached+out~={fmt(noncached)}",
            row["cwd"],
            row["title"],
            row["session_id"],
        ]))


def parse_args():
    parser = argparse.ArgumentParser(
        description="Print a detailed Codex token usage breakdown for one local day.",
    )
    parser.add_argument("date", help="Local date in YYYY-MM-DD format.")
    parser.add_argument(
        "session_roots",
        nargs="+",
        type=Path,
        help="Session directories to scan.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    target = dt.date.fromisoformat(args.date)
    by_hour, by_cwd, by_session, components = collect_daily_breakdown(
        target,
        args.session_roots,
    )
    print_daily_breakdown(target, by_hour, by_cwd, by_session, components)


if __name__ == "__main__":
    main()
