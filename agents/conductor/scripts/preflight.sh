#!/usr/bin/env bash
# Availability probe. Decides once, cheaply, which engines this run can
# actually use — so the workflow degrades deliberately instead of
# discovering the outage halfway through and dying.
#
# Real failures this catches, all observed on this machine:
#   - "Insufficient balance" (opencode/* zen provider, no credit)
#   - "You've hit your usage limit" (per-model quota, resets on a date)
#   - "reasoning_effort does not support 'none' with this model"
#   - provider not authenticated
#
# Probes are cheap: when a model is unavailable the request is rejected
# before tokens are billed, which is exactly the case that matters.
#
# The plan engine is not optional. It runs the planner, the implementer it
# dispatches, and the review panel — the three roles that have `.md`
# definitions. There is no fallback for it, so a failure here stops the run
# rather than quietly degrading it into something the definitions do not
# describe.
#
# Env: RUN_DIR SCRIPTS_DIR REPO PLAN_ENGINE PLAN_MODEL
#      [TEST_ENGINE] [TEST_MODEL] [GEMINI_MODEL] [IMPL_AGENT]
set -uo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${PLAN_ENGINE:?}" "${PLAN_MODEL:?}"
: "${TEST_ENGINE:=}" "${TEST_MODEL:=}" "${GEMINI_MODEL:=}" "${IMPL_AGENT:=implementer}"

WORK="$RUN_DIR/preflight"
mkdir -p "$WORK"
echo "Reply with exactly: ok" > "$WORK/probe.txt"

probe() {
  # $1 = slot, $2 = engine, $3 = model. Echoes "true|reason" or "false|reason".
  local slot="$1" engine="$2" model="$3"
  [ -z "$engine" ] || [ -z "$model" ] && { echo "false|not configured"; return; }

  local dir="$WORK/$slot"
  mkdir -p "$dir"

  if RUN_DIR="$WORK" REPO="$REPO" SCRIPTS_DIR="$SCRIPTS_DIR" \
     ENGINE="$engine" MODEL="$model" \
     "$SCRIPTS_DIR/agent-run.sh" "preflight_$slot" \
     "$WORK/probe.txt" "$dir" >/dev/null 2>&1; then
    echo "true|ok"
  else
    local reason
    # Each engine reports failure somewhere different, so look in all three
    # places rather than binding the probe to one engine's shape.
    reason=$(python3 -c '
import json, pathlib, sys

d = pathlib.Path(sys.argv[1])
msgs = []

events = d / "events.json"
if events.exists():
    for line in events.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if e.get("type") == "error":
            err = e.get("error") or {}
            m = (err.get("data") or {}).get("message") or err.get("name")
            if m:
                msgs.append(str(m))

result = d / "result.json"
if not msgs and result.exists():
    try:
        r = json.loads(result.read_text())
    except json.JSONDecodeError:
        r = {}
    if r.get("is_error"):
        msgs.append(str(r.get("result") or r.get("api_error_status") or "error"))

stderr = d / "stderr.log"
if not msgs and stderr.exists():
    tail = [ln.strip() for ln in stderr.read_text(errors="replace").splitlines() if ln.strip()]
    msgs.extend(tail[-2:])

print("; ".join(dict.fromkeys(msgs))[:300] or "probe failed")
' "$dir")
    echo "false|$reason"
  fi
}

PLAN=$(probe plan "$PLAN_ENGINE" "$PLAN_MODEL")
TESTS=$(probe tests "$TEST_ENGINE" "$TEST_MODEL")

PLAN_OK="${PLAN%%|*}";   PLAN_WHY="${PLAN#*|}"
TESTS_OK="${TESTS%%|*}"; TESTS_WHY="${TESTS#*|}"

# The implementer runs inside the plan engine's session — there is one
# implementer definition and it declares no model. So the only thing that
# can fail here independently is the plan engine itself, already probed
# above. Kept as a named check so the ledger records the decision.
if [ "$PLAN_OK" != true ]; then
  IMPL_OK=false; IMPL_WHY="plan engine unavailable — the implementer runs in its session"
else
  IMPL_OK=true;  IMPL_WHY="ok"
fi

# The independent reviewer does NOT go through the plan engine — separate
# binary, separate auth, separate failure domain. A no-cost capability
# probe: look for the binary rather than spending a call.
#
# GEM_OK here means "a genuinely different model family is available". When
# it is false the reviewer still runs, via Opus 5 through `claude -p` — it
# just is not an independent second opinion, and the synthesizer is told so.
: "${ANTIGRAVITY_BIN:=antigravity}"
if command -v "$ANTIGRAVITY_BIN" >/dev/null 2>&1; then
  GEM_OK=true;  GEM_WHY="antigravity CLI present"
elif command -v claude >/dev/null 2>&1; then
  GEM_OK=false; GEM_WHY="antigravity not on PATH — Opus 5 via claude code will stand in"
else
  GEM_OK=false; GEM_WHY="neither antigravity nor claude on PATH"
fi

PLAN_ENGINE="$PLAN_ENGINE" PLAN_MODEL="$PLAN_MODEL" \
TEST_ENGINE="$TEST_ENGINE" TEST_MODEL="$TEST_MODEL" \
GEMINI_MODEL="$GEMINI_MODEL" IMPL_AGENT="$IMPL_AGENT" \
python3 -c '
import json, os, sys

plan_ok  = sys.argv[1] == "true"
tests_ok = sys.argv[2] == "true"
gem_ok   = sys.argv[3] == "true"
impl_ok  = sys.argv[4] == "true"
plan_why, tests_why, gem_why, impl_why = sys.argv[5:9]

notes = []
if not plan_ok:
    notes.append(f"Plan engine unavailable ({plan_why}) — the planner, implementer, and review panel all run on it. The lane cannot proceed.")
if not impl_ok:
    notes.append(f"Implementation role unavailable ({impl_why}).")
if not tests_ok:
    notes.append(f"Test model unavailable ({tests_why}) — the independent test pass will be skipped.")
if not gem_ok:
    notes.append(f"Independent reviewer degraded ({gem_why}) — the plan review panel loses its cross-family opinion.")

json.dump({
    "plan_available": plan_ok,   "plan_reason": plan_why,
    "plan_engine": os.environ["PLAN_ENGINE"], "plan_model": os.environ["PLAN_MODEL"],
    "impl_available": impl_ok,   "impl_reason": impl_why,
    "impl_agent": os.environ["IMPL_AGENT"],
    "tests_available": tests_ok, "tests_reason": tests_why,
    "test_engine": os.environ["TEST_ENGINE"], "test_model": os.environ["TEST_MODEL"],
    "gemini_available": gem_ok,  "gemini_reason": gem_why,
    "gemini_model": os.environ["GEMINI_MODEL"],
    "ready": plan_ok and impl_ok,
    "degraded": not (plan_ok and impl_ok and tests_ok),
    "notes": notes,
}, sys.stdout)
' "$PLAN_OK" "$TESTS_OK" "$GEM_OK" "$IMPL_OK" \
  "$PLAN_WHY" "$TESTS_WHY" "$GEM_WHY" "$IMPL_WHY"

{
  echo "preflight: plan   =$PLAN_OK  ($PLAN_WHY)"
  echo "preflight: impl   =$IMPL_OK  ($IMPL_WHY)"
  echo "preflight: tests  =$TESTS_OK ($TESTS_WHY)"
  echo "preflight: gemini =$GEM_OK   ($GEM_WHY)"
} >&2
