#!/usr/bin/env bash
# Engine dispatcher. Every role script calls this instead of a specific
# engine, so swapping engines is a config change, not a code change.
#
# Usage: agent-run.sh <label> <prompt-file> <work-dir> [--write]
# Env:   ENGINE MODEL RUN_DIR REPO SCRIPTS_DIR
#        AGENT_DEF     optional — file holding a role definition's body, used
#                      as the system prompt. Produced by agent-def.py from
#                      agents/<role>.md, which is the source of truth.
#        AGENT_TOOLS   optional — comma-separated tool allowlist, taken from
#                      the same definition's frontmatter.
#        SUBAGENTS_JSON optional — --agents payload, so a role that dispatches
#                      (the planner) can reach the roles it dispatches.
#
# Adding an engine: drop engines/<name>.sh implementing the contract in
# engines/README.md. Nothing here needs to change except MODEL_SHAPE below.
set -uo pipefail

LABEL="${1:?agent-run: label required}"
PROMPT_FILE="${2:?agent-run: prompt file required}"
WORK="${3:?agent-run: work dir required}"
MODE="${4:-}"

: "${ENGINE:?agent-run: ENGINE not set}"
: "${MODEL:?agent-run: MODEL not set}"
: "${RUN_DIR:?}" "${REPO:?}" "${SCRIPTS_DIR:?}"
: "${AGENT_DEF:=}" "${AGENT_TOOLS:=}" "${SUBAGENTS_JSON:=}"
export AGENT_DEF AGENT_TOOLS SUBAGENTS_JSON

# A missing definition file means the role silently runs as a generic
# assistant — the exact failure the .md files exist to prevent. Fail loudly.
if [ -n "$AGENT_DEF" ] && [ ! -s "$AGENT_DEF" ]; then
  echo "agent-run: AGENT_DEF is set but '$AGENT_DEF' is missing or empty" >&2
  exit 2
fi

ADAPTER="$SCRIPTS_DIR/engines/${ENGINE}.sh"

if [ ! -x "$ADAPTER" ]; then
  AVAILABLE=$(find "$SCRIPTS_DIR/engines" -maxdepth 1 -name '*.sh' -exec basename {} .sh \; 2>/dev/null | sort | tr '\n' ' ')
  echo "agent-run: unknown engine '$ENGINE'. Available: ${AVAILABLE:-none}" >&2
  mkdir -p "$WORK" "$RUN_DIR/tokens"
  : > "$WORK/last.txt"
  SAFE=$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '_')
  ENGINE="$ENGINE" MODEL="$MODEL" LABEL="$LABEL" python3 -c '
import json, os, sys
json.dump({"label": os.environ["LABEL"], "engine": os.environ["ENGINE"],
           "model": os.environ["MODEL"], "steps": 0, "cost_usd": 0.0,
           "errors": ["unknown engine: " + os.environ["ENGINE"]],
           "input_tokens": 0, "output_tokens": 0, "reasoning_tokens": 0,
           "cache_read_tokens": 0, "cache_write_tokens": 0,
           "total_tokens": 0}, sys.stdout)
' > "$RUN_DIR/tokens/${SAFE}.json" 2>/dev/null || true
  exit 2
fi

# Model ids are engine-specific and NOT interchangeable. Handing codex an
# opencode-style "provider/model" id fails at the API with an opaque error
# minutes later; catching the shape here fails in a millisecond with a
# useful one.
case "$ENGINE" in
  opencode)
    case "$MODEL" in
      */*) ;;
      *) echo "agent-run: opencode expects 'provider/model', got '$MODEL'" >&2; exit 2 ;;
    esac
    ;;
  codex|claude-code)
    case "$MODEL" in
      */*) echo "agent-run: $ENGINE expects a bare model id, got '$MODEL'" >&2; exit 2 ;;
    esac
    ;;
esac

exec "$ADAPTER" "$LABEL" "$MODEL" "$PROMPT_FILE" "$WORK" "$MODE"
