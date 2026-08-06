#!/usr/bin/env bash
# opencode engine adapter. See engines/README.md for the contract.
#
# Model id format: provider/model  (e.g. parley/openai/gpt-5.6-sol)
# Counter semantics: per-step step_finish events → SUM.
set -uo pipefail

LABEL="${1:?opencode: label required}"
MODEL="${2:?opencode: model required}"
PROMPT_FILE="${3:?opencode: prompt file required}"
WORK="${4:?opencode: work dir required}"
MODE="${5:-}"

: "${RUN_DIR:?}" "${REPO:?}"
: "${AGENT_DEF:=}"
mkdir -p "$WORK" "$RUN_DIR/tokens"

EVENTS="$WORK/events.json"
LAST="$WORK/last.txt"

ARGS=(run --format json -m "$MODEL" --dir "$REPO")
# --auto auto-approves permission prompts. Required for unattended editing;
# withheld from read-only roles so a reviewer cannot mutate what it reviews.
[ "$MODE" = "--write" ] && ARGS+=(--auto)

# `opencode run` takes no system-prompt flag, so a role definition is
# prepended to the prompt instead. Same text, weaker separation — a
# prepended instruction is easier to argue a model out of than a system
# prompt. That is why claude-code is the default engine for the roles whose
# boundaries are load-bearing, and this path is the fallback.
EFFECTIVE="$PROMPT_FILE"
if [ -n "$AGENT_DEF" ]; then
  EFFECTIVE="$WORK/prompt.effective.txt"
  { cat "$AGENT_DEF"; printf '\n\n---\n\n'; cat "$PROMPT_FILE"; } > "$EFFECTIVE"
fi

STATUS=0
timeout 7200 opencode "${ARGS[@]}" "$(cat "$EFFECTIVE")" \
  < /dev/null > "$EVENTS" 2>"$WORK/stderr.log" || STATUS=$?

# opencode streams; there is no --output-last-message equivalent, so
# reassemble the final text from the `text` parts.
python3 -c '
import json, pathlib, sys
events, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
chunks = []
if events.exists():
    for line in events.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if e.get("type") == "text":
            t = (e.get("part") or {}).get("text") or e.get("text")
            if t:
                chunks.append(t)
out.write_text("".join(chunks))
' "$EVENTS" "$LAST"

SAFE=$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '_')
MODEL="$MODEL" python3 -c '
import json, os, pathlib, sys

events = pathlib.Path(sys.argv[1])
label = sys.argv[2]

t = dict.fromkeys((
    "input_tokens", "output_tokens", "reasoning_tokens",
    "cache_read_tokens", "cache_write_tokens", "total_tokens"), 0)
cost, steps, errors, session = 0.0, 0, [], None

if events.exists():
    for line in events.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        session = session or e.get("sessionID")
        if e.get("type") == "error":
            err = e.get("error") or {}
            m = (err.get("data") or {}).get("message") or err.get("name")
            if m:
                errors.append(str(m))
            continue
        part = e.get("part") or {}
        tok = part.get("tokens")
        if not isinstance(tok, dict):
            continue
        # Per-step counters: SUM. (codex is cumulative and takes the max.)
        steps += 1
        cache = tok.get("cache") or {}
        t["input_tokens"] += int(tok.get("input") or 0)
        t["output_tokens"] += int(tok.get("output") or 0)
        t["reasoning_tokens"] += int(tok.get("reasoning") or 0)
        t["cache_read_tokens"] += int(cache.get("read") or 0)
        t["cache_write_tokens"] += int(cache.get("write") or 0)
        t["total_tokens"] += int(tok.get("total") or 0)
        if isinstance(part.get("cost"), (int, float)):
            cost += float(part["cost"])

if not t["total_tokens"]:
    t["total_tokens"] = t["input_tokens"] + t["output_tokens"]

json.dump({"label": label, "engine": "opencode", "model": os.environ["MODEL"],
           "session_id": session, "steps": steps, "cost_usd": round(cost, 6),
           "errors": list(dict.fromkeys(errors)), **t}, sys.stdout, indent=2)
' "$EVENTS" "$LABEL" > "$RUN_DIR/tokens/${SAFE}.json" 2>/dev/null || true

exit "$STATUS"
