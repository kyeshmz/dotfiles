#!/usr/bin/env python3
"""Before/after token ledger for a conductor run.

Two independent sources have to be reconciled:

  * Conductor's own UsageTracker covers provider-backed agents (the Claude
    ones). It is *displayed*, never written to the result JSON, so run.sh
    captures it with `--log-file` and this scrapes that log.
  * opencode runs as `type: script`, which UsageTracker never sees. Each
    engine adapter drops its own normalized JSON into $RUN_DIR/tokens/.

Phases:
  before  — snapshot the pre-run baseline from `opencode stats`
  after   — read both sources, diff the baseline, emit the ledger

Usage: token-report.py --phase before|after --run-dir DIR
       (also reads $RUN_DIR / $PHASE)
"""

from __future__ import annotations

import argparse
import datetime as dt
import glob
import json
import os
import pathlib
import re
import subprocess
import sys

TOKEN_FIELDS = (
    "input_tokens",
    "output_tokens",
    "reasoning_tokens",
    "cache_read_tokens",
    "cache_write_tokens",
    "total_tokens",
)


def opencode_stats() -> dict:
    """Account-wide totals from `opencode stats`.

    Used as an independent cross-check on the per-step numbers. The command
    renders a box-drawing table with human-scaled values (278.6M, 3.5K), so
    this parses and expands the suffixes. Best-effort: a parse failure
    returns empty rather than breaking the run.
    """
    try:
        out = subprocess.run(
            ["opencode", "stats"],
            capture_output=True, text=True, timeout=120,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return {}

    def expand(tok: str) -> float | None:
        m = re.fullmatch(r"\$?([\d,]+(?:\.\d+)?)([KMB]?)", tok.strip())
        if not m:
            return None
        val = float(m.group(1).replace(",", ""))
        return val * {"": 1, "K": 1e3, "M": 1e6, "B": 1e9}[m.group(2)]

    wanted = {
        "Input": "input_tokens",
        "Output": "output_tokens",
        "Cache Read": "cache_read_tokens",
        "Cache Write": "cache_write_tokens",
        "Total Cost": "cost_usd",
        "Sessions": "sessions",
    }
    # Rows look like  "│Input                    278.6M │" — the label and
    # value share a single cell, separated by run-of-spaces padding.
    row = re.compile(r"^(.+?)\s{2,}(\$?[\d,]+(?:\.\d+)?[KMB]?)$")
    stats: dict[str, float] = {}
    for line in out.splitlines():
        for cell in (c.strip() for c in line.split("│")):
            m = row.match(cell)
            if not m:
                continue
            key = wanted.get(m.group(1).strip())
            if key:
                v = expand(m.group(2))
                if v is not None:
                    stats[key] = v
    return stats


def parse_conductor_log(run_dir: pathlib.Path) -> list[dict]:
    """Scrape per-agent usage rows out of Conductor's --log-file output.

    display_usage_summary() renders a Rich table and there is no machine
    format, so this reads the table. Returns [] when absent — not an error,
    just means no provider agent has run yet.
    """
    rows: list[dict] = []
    num = re.compile(r"[\d,]+")
    for path in sorted(glob.glob(str(run_dir / "*.log"))):
        try:
            text = pathlib.Path(path).read_text(errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            if "│" not in line:
                continue
            cells = [c.strip() for c in line.split("│") if c.strip()]
            if len(cells) < 3:
                continue
            name = cells[0]
            if not name or name.lower() in {"agent", "total", "totals", "model"}:
                continue
            nums = [
                int(m.replace(",", ""))
                for cell in cells[1:]
                for m in num.findall(cell)
                if m.strip(",")
            ]
            if len(nums) >= 2:
                rows.append({
                    "agent": name,
                    "engine": "claude/conductor",
                    "input_tokens": nums[0],
                    "output_tokens": nums[1],
                    "total_tokens": nums[2] if len(nums) > 2 else nums[0] + nums[1],
                })
    return rows


def opencode_steps(run_dir: pathlib.Path) -> list[dict]:
    out = []
    tokens_dir = run_dir / "tokens"
    if not tokens_dir.exists():
        return out
    for path in sorted(tokens_dir.glob("*.json")):
        if path.name.startswith("_"):
            continue
        try:
            out.append(json.loads(path.read_text()))
        except (OSError, json.JSONDecodeError):
            continue
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", default=os.environ.get("PHASE", "after"))
    ap.add_argument("--run-dir", default=os.environ.get("RUN_DIR"))
    args = ap.parse_args()

    if not args.run_dir:
        print("token-report: RUN_DIR not set", file=sys.stderr)
        return 2

    run_dir = pathlib.Path(args.run_dir)
    (run_dir / "tokens").mkdir(parents=True, exist_ok=True)
    baseline_path = run_dir / "tokens" / "_baseline.json"
    stamp = dt.datetime.now().isoformat(timespec="seconds")

    if args.phase == "before":
        baseline = {"captured_at": stamp, "opencode_stats": opencode_stats()}
        baseline_path.write_text(json.dumps(baseline, indent=2))
        json.dump({"phase": "before", **baseline}, sys.stdout, indent=2)
        print()
        return 0

    # ---- after ----
    try:
        baseline = json.loads(baseline_path.read_text())
    except (OSError, json.JSONDecodeError):
        baseline = {"captured_at": None, "opencode_stats": {}}

    before = baseline.get("opencode_stats", {})
    after = opencode_stats()
    account_delta = {
        k: max(0.0, after.get(k, 0) - before.get(k, 0))
        for k in set(before) | set(after)
    }

    steps = opencode_steps(run_dir)
    claude_rows = parse_conductor_log(run_dir)

    step_sum = {f: sum(int(s.get(f, 0) or 0) for s in steps) for f in TOKEN_FIELDS}
    step_cost = round(sum(float(s.get("cost_usd", 0) or 0) for s in steps), 6)
    claude_sum = {
        "input_tokens": sum(r["input_tokens"] for r in claude_rows),
        "output_tokens": sum(r["output_tokens"] for r in claude_rows),
        "total_tokens": sum(r["total_tokens"] for r in claude_rows),
    }
    errors = [e for s in steps for e in s.get("errors", [])]

    report = {
        "phase": "after",
        "run_dir": str(run_dir),
        "before_captured_at": baseline.get("captured_at"),
        "after_captured_at": stamp,
        "opencode": {
            "per_step": steps,
            # Headline uses the per-step sum: it is the direct measurement
            # and is scoped to this run. The account delta is a cross-check
            # that also moves if unrelated opencode activity ran meanwhile.
            "step_sum": step_sum,
            "cost_usd": step_cost,
            "account_before": before,
            "account_after": after,
            "account_delta": account_delta,
        },
        "claude": {"per_agent": claude_rows, "sum": claude_sum},
        "grand_total_tokens": step_sum["total_tokens"] + claude_sum["total_tokens"],
        "thinking_tokens": step_sum["reasoning_tokens"],
        "cost_usd": step_cost,
        "errors": list(dict.fromkeys(errors)),
    }
    (run_dir / "tokens" / "_report.json").write_text(json.dumps(report, indent=2))

    w = sys.stderr.write
    w("\n══ TOKEN LEDGER ══\n")
    w(f"  baseline : {baseline.get('captured_at')}\n")
    w(f"  report   : {stamp}\n\n")

    if claude_rows:
        w("  Claude — Conductor UsageTracker\n")
        for r in claude_rows:
            w(f"    {r['agent']:<26} in {r['input_tokens']:>10,}  out {r['output_tokens']:>9,}\n")
        w(f"    {'subtotal':<26} in {claude_sum['input_tokens']:>10,}  out {claude_sum['output_tokens']:>9,}\n\n")
    else:
        w("  Claude: no usage table in log (run.sh passes --log-file; check it)\n\n")

    if steps:
        w("  opencode — harvested per step\n")
        for s in steps:
            w(f"    {s.get('label', '?'):<26} in {s.get('input_tokens', 0):>10,}"
              f"  out {s.get('output_tokens', 0):>9,}"
              f"  think {s.get('reasoning_tokens', 0):>8,}"
              f"  ${s.get('cost_usd', 0):>7.4f}\n")
        w(f"    {'subtotal':<26} in {step_sum['input_tokens']:>10,}"
          f"  out {step_sum['output_tokens']:>9,}"
          f"  think {step_sum['reasoning_tokens']:>8,}"
          f"  ${step_cost:>7.4f}\n\n")
    else:
        w("  opencode: no steps ran\n\n")

    if account_delta.get("total_tokens") or account_delta.get("input_tokens"):
        w(f"  account delta (cross-check): in {int(account_delta.get('input_tokens', 0)):,}"
          f"  out {int(account_delta.get('output_tokens', 0)):,}\n")
    w(f"  GRAND TOTAL       : {report['grand_total_tokens']:,} tokens\n")
    w(f"  of which thinking : {report['thinking_tokens']:,}\n")
    w(f"  opencode cost     : ${step_cost:.4f}\n")
    if errors:
        w("\n  ⚠ errors reported by opencode steps:\n")
        for e in dict.fromkeys(errors):
            w(f"    - {e}\n")
    w("══════════════════\n\n")

    json.dump(report, sys.stdout, indent=2)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
