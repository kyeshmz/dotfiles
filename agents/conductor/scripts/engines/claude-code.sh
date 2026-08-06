#!/usr/bin/env bash
# claude-code engine adapter. See engines/README.md for the contract.
#
# Model id format: bare model  (e.g. claude-opus-5)
# Counter semantics: one usage object per run, taken as-is.
#
# Doubles as the universal fallback: it needs no extra credit beyond the
# Claude subscription already backing the Conductor `claude` provider, so
# it is the engine most likely to be available when others are capped.
set -uo pipefail

LABEL="${1:?claude-code: label required}"
MODEL="${2:?claude-code: model required}"
PROMPT_FILE="${3:?claude-code: prompt file required}"
WORK="${4:?claude-code: work dir required}"
MODE="${5:-}"

: "${RUN_DIR:?}" "${REPO:?}"
: "${AGENT_DEF:=}" "${AGENT_TOOLS:=}" "${SUBAGENTS_JSON:=}"
mkdir -p "$WORK" "$RUN_DIR/tokens"

RESULT="$WORK/result.json"
LAST="$WORK/last.txt"

ARGS=(-p)

# Tool allowlist. When a role definition declared one, that list wins — the
# .md is the source of truth for what the role may touch, and honouring it
# here is what makes "the planner cannot dispatch while it is planning" a
# mechanism rather than a request. Otherwise fall back to the old defaults:
# read-only roles get an explicit allowlist so a reviewer cannot edit what
# it is reviewing.
#
# ORDER MATTERS: --allowed-tools is variadic and greedy. If it is the last
# flag before the positional prompt it swallows the prompt as another tool
# name, and claude then dies with "Input must be provided...". Keeping it
# first — with non-variadic flags after it — is what stops that.
if [ -n "$AGENT_TOOLS" ]; then
  ARGS+=(--allowed-tools "$AGENT_TOOLS")
elif [ "$MODE" != "--write" ]; then
  ARGS+=(--allowed-tools "Read,Glob,Grep")
fi

# acceptEdits is still required for a write role: the allowlist says which
# tools exist, the permission mode says whether they run unattended.
[ "$MODE" = "--write" ] && ARGS+=(--permission-mode acceptEdits)

# The role definition's body replaces the default system prompt, so the
# agent that runs here IS the role — not a generic assistant asked to
# behave like one.
[ -n "$AGENT_DEF" ] && ARGS+=(--system-prompt-file "$AGENT_DEF")

# Roles that dispatch (the planner) need the roles they dispatch defined in
# the same session. Passed as JSON rather than relying on ~/.claude/agents,
# so a lane run from a checkout uses that checkout's definitions.
[ -n "$SUBAGENTS_JSON" ] && ARGS+=(--agents "$SUBAGENTS_JSON")

ARGS+=(--model "$MODEL" --output-format json)

STATUS=0
( cd "$REPO" && timeout 7200 claude "${ARGS[@]}" "$(cat "$PROMPT_FILE")" \
    < /dev/null ) > "$RESULT" 2>"$WORK/stderr.log" || STATUS=$?

SAFE=$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '_')
MODEL="$MODEL" python3 -c '
import json, os, pathlib, sys

result, last, label = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]

d = {}
if result.exists():
    try:
        d = json.loads(result.read_text())
    except json.JSONDecodeError:
        d = {}

last.write_text(d.get("result") or "")

u = d.get("usage") or {}
inp = int(u.get("input_tokens") or 0)
out = int(u.get("output_tokens") or 0)
errors = []
if d.get("is_error"):
    errors.append(str(d.get("result") or d.get("api_error_status") or "claude-code error"))

json.dump({
    "label": label, "engine": "claude-code", "model": os.environ["MODEL"],
    "session_id": d.get("session_id"),
    "steps": int(d.get("num_turns") or 0),
    "cost_usd": float(d.get("total_cost_usd") or 0.0),
    "errors": errors,
    "input_tokens": inp,
    "output_tokens": out,
    # Claude reports thinking inside output_tokens rather than separately,
    # so this stays 0 instead of double-counting it.
    "reasoning_tokens": 0,
    "cache_read_tokens": int(u.get("cache_read_input_tokens") or 0),
    "cache_write_tokens": int(u.get("cache_creation_input_tokens") or 0),
    "total_tokens": inp + out,
}, sys.stdout, indent=2)
' "$RESULT" "$LAST" "$LABEL" > "$RUN_DIR/tokens/${SAFE}.json" 2>/dev/null || true

exit "$STATUS"
