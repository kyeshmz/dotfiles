#!/usr/bin/env bash
# codex engine adapter. See engines/README.md for the contract.
#
# Model id format: bare model  (e.g. gpt-5.6-terra, gpt-5.4-mini)
# Counter semantics: cumulative total_token_usage → MAX, not sum.
#
# Two quirks worth knowing, both observed on this machine:
#   - codex exec reads stdin unless it is closed → `< /dev/null` is required
#   - it refuses to run outside a trusted git dir → --skip-git-repo-check
#
# Token counts sometimes never reach stdout. When that happens this falls
# back to the rollout file under ~/.codex/sessions, matched by thread_id,
# which always carries them.
set -uo pipefail

LABEL="${1:?codex: label required}"
MODEL="${2:?codex: model required}"
PROMPT_FILE="${3:?codex: prompt file required}"
WORK="${4:?codex: work dir required}"
MODE="${5:-}"

: "${RUN_DIR:?}" "${REPO:?}"
: "${AGENT_DEF:=}"
mkdir -p "$WORK" "$RUN_DIR/tokens"

EVENTS="$WORK/events.jsonl"
LAST="$WORK/last.txt"

SANDBOX=read-only
[ "$MODE" = "--write" ] && SANDBOX=workspace-write

# `codex exec` takes no system-prompt flag, so a role definition is
# prepended to the prompt. See the same note in opencode.sh.
EFFECTIVE="$PROMPT_FILE"
if [ -n "$AGENT_DEF" ]; then
  EFFECTIVE="$WORK/prompt.effective.txt"
  { cat "$AGENT_DEF"; printf '\n\n---\n\n'; cat "$PROMPT_FILE"; } > "$EFFECTIVE"
fi

STATUS=0
timeout 7200 codex exec \
  --model "$MODEL" \
  --sandbox "$SANDBOX" \
  --cd "$REPO" \
  --skip-git-repo-check \
  --json \
  --output-last-message "$LAST" \
  "$(cat "$EFFECTIVE")" \
  < /dev/null > "$EVENTS" 2>"$WORK/stderr.log" || STATUS=$?

[ -f "$LAST" ] || : > "$LAST"

SAFE=$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '_')
MODEL="$MODEL" python3 -c '
import json, os, pathlib, sys

events = pathlib.Path(sys.argv[1])
label = sys.argv[2]

FIELDS = ("input_tokens", "cached_input_tokens", "cache_write_input_tokens",
          "output_tokens", "reasoning_output_tokens", "total_tokens")


def read(path):
    if not path or not path.exists():
        return
    for line in path.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            yield json.loads(line)
        except json.JSONDecodeError:
            continue


def walk(node):
    """Yield every dict that looks like a usage record, at any depth.

    The stdout stream and the rollout file nest these differently; walking
    avoids binding to either shape.
    """
    if isinstance(node, dict):
        if "input_tokens" in node and "output_tokens" in node:
            yield node
        for v in node.values():
            yield from walk(v)
    elif isinstance(node, list):
        for v in node:
            yield from walk(v)


def collect(path):
    best = dict.fromkeys(FIELDS, 0)
    found = False
    for e in read(path):
        for u in walk(e):
            found = True
            # Cumulative counters: MAX. Summing would multiply-count.
            for f in FIELDS:
                v = u.get(f)
                if isinstance(v, (int, float)) and int(v) > best[f]:
                    best[f] = int(v)
    return best if found else None


def rollout_for(path):
    """Locate this run’s rollout file via its thread_id."""
    tid = None
    for e in read(path):
        tid = e.get("thread_id") or (e.get("payload") or {}).get("thread_id")
        if tid:
            break
    if not tid:
        return None
    root = pathlib.Path.home() / ".codex" / "sessions"
    hits = sorted(root.rglob(f"*{tid}*.jsonl"))
    return hits[-1] if hits else None


usage = collect(events)
if usage is None:
    usage = collect(rollout_for(events)) or dict.fromkeys(FIELDS, 0)

errors = []
for e in read(events):
    if e.get("type") in ("error", "turn.failed"):
        m = e.get("message") or (e.get("error") or {}).get("message")
        if m:
            errors.append(str(m))

total = usage["total_tokens"] or (usage["input_tokens"] + usage["output_tokens"])
json.dump({
    "label": label, "engine": "codex", "model": os.environ["MODEL"],
    "steps": 1 if total else 0,
    # codex reports no cost; the ledger sums what it has and this
    # contributes 0 rather than a fabricated number.
    "cost_usd": 0.0,
    "errors": list(dict.fromkeys(errors)),
    "input_tokens": usage["input_tokens"],
    "output_tokens": usage["output_tokens"],
    "reasoning_tokens": usage["reasoning_output_tokens"],
    "cache_read_tokens": usage["cached_input_tokens"],
    "cache_write_tokens": usage["cache_write_input_tokens"],
    "total_tokens": total,
}, sys.stdout, indent=2)
' "$EVENTS" "$LABEL" > "$RUN_DIR/tokens/${SAFE}.json" 2>/dev/null || true

exit "$STATUS"
