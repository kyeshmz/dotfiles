#!/usr/bin/env bash
# The independent-model reviewer.
#
# Transport order:
#   1. `antigravity` CLI  — Gemini. Deliberately NOT routed through
#      opencode: separate binary, separate auth, separate failure domain,
#      so an opencode outage cannot take this reviewer out too.
#   2. Opus 5 via `claude -p` — the fallback when antigravity is missing or
#      fails.
#
# NOTE: antigravity is not installed on this machine, so path 2 is what
# actually runs today. The output always records which transport served the
# review, because "a second opinion from a different model family" and "a
# second Opus 5" are not the same evidence and must not be confused in the
# synthesizer's input.
#
# Env: RUN_DIR TASK PLAN_MARKDOWN [PLAN_PATH] [REPO]
#      [GEMINI_MODEL] [ANTIGRAVITY_BIN] [FALLBACK_MODEL]
set -uo pipefail

: "${RUN_DIR:?}" "${TASK:?}" "${PLAN_MARKDOWN:?}"
: "${PLAN_PATH:=}" "${REPO:=}"
: "${GEMINI_MODEL:=gemini-3-pro}"
: "${ANTIGRAVITY_BIN:=antigravity}"
: "${FALLBACK_MODEL:=claude-opus-5}"

WORK="$RUN_DIR/reviews/gemini"
mkdir -p "$WORK" "$RUN_DIR/tokens"

cat > "$WORK/prompt.txt" <<PROMPT
You are reviewing an implementation plan written by a different model. Other
reviewers are examining this same plan and cannot see your findings, nor you
theirs. Do not hedge toward a consensus you cannot observe — state what you
actually think.

The plan is executed one phase at a time by a single implementer whose entire
context is the plan file plus a per-phase dispatch derived from it. There is
no conversation behind it and it cannot ask questions.

Review in priority order:
1. CORRECTNESS — will this accomplish the task? What does it miss?
2. PHASE BOUNDARIES — each phase must leave the tree compiling with existing
   tests passing. Does any phase change a symbol whose consumers are only
   updated later? Is any file created and never wired in by the last phase?
3. SELF-CONTAINMENT — can a phase be executed by an agent that sees only the
   plan file? Every decision it needs must already be closed in the text: no
   open questions, no "handle the edge cases", no alternatives left live.
4. VERIFICATION — is every automated-verification line a literal command,
   and does it actually distinguish done from not-done?

Respond with ONLY a JSON object, no prose and no code fences:
{"verdict":"approved|revise|reject","blocking_issues":["..."],"notes":"..."}

Repository: ${REPO}

Plan path: ${PLAN_PATH}

Original task:
${TASK}

Proposed plan:
${PLAN_MARKDOWN}
PROMPT

RAW="$WORK/response.txt"
TRANSPORT="none"
ACTUAL_MODEL=""

# ── 1. antigravity ───────────────────────────────────────────────────
if command -v "$ANTIGRAVITY_BIN" >/dev/null 2>&1; then
  TRANSPORT="antigravity"
  ACTUAL_MODEL="$GEMINI_MODEL"
  "$ANTIGRAVITY_BIN" --model "$GEMINI_MODEL" --prompt "$(cat "$WORK/prompt.txt")" \
    < /dev/null > "$RAW" 2>"$WORK/antigravity.err" || TRANSPORT="antigravity-failed"

  # A zero exit with empty output is still a failure.
  if [ "$TRANSPORT" = "antigravity" ] && [ ! -s "$RAW" ]; then
    TRANSPORT="antigravity-failed"
  fi
fi

# ── 2. Opus 5 via claude code ────────────────────────────────────────
if [ "$TRANSPORT" != "antigravity" ]; then
  WHY="$TRANSPORT"
  [ "$WHY" = "none" ] && WHY="antigravity CLI not on PATH"
  echo "gemini-review: $WHY — falling back to $FALLBACK_MODEL via claude code" >&2

  TRANSPORT="claude-code-fallback"
  ACTUAL_MODEL="$FALLBACK_MODEL"

  if claude -p --model "$FALLBACK_MODEL" --output-format json \
       "$(cat "$WORK/prompt.txt")" \
       < /dev/null > "$WORK/claude.json" 2>"$WORK/claude.err"; then
    python3 -c '
import json, pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
try:
    d = json.loads(src.read_text())
except (OSError, json.JSONDecodeError):
    dst.write_text("")
    raise SystemExit(0)
dst.write_text(d.get("result") or "")
usage = d.get("usage") or {}
pathlib.Path(str(dst) + ".usage.json").write_text(json.dumps({
    "input_tokens": int(usage.get("input_tokens") or 0),
    "output_tokens": int(usage.get("output_tokens") or 0),
    "cache_read_tokens": int(usage.get("cache_read_input_tokens") or 0),
    "cache_write_tokens": int(usage.get("cache_creation_input_tokens") or 0),
    "cost_usd": float(d.get("total_cost_usd") or 0.0),
}))
' "$WORK/claude.json" "$RAW"
  else
    TRANSPORT="claude-code-failed"
  fi
fi

# ── token ledger entry ───────────────────────────────────────────────
TRANSPORT="$TRANSPORT" ACTUAL_MODEL="$ACTUAL_MODEL" python3 -c '
import json, os, pathlib, sys
work = pathlib.Path(sys.argv[1])
u = {}
uf = work / "response.txt.usage.json"
if uf.exists():
    try:
        u = json.loads(uf.read_text())
    except json.JSONDecodeError:
        u = {}
inp = int(u.get("input_tokens") or 0)
out = int(u.get("output_tokens") or 0)
json.dump({
    "label": "review_independent",
    "engine": os.environ["TRANSPORT"],
    "model": os.environ["ACTUAL_MODEL"],
    "steps": 1 if (inp or out) else 0,
    "cost_usd": float(u.get("cost_usd") or 0.0),
    "errors": [],
    "input_tokens": inp,
    "output_tokens": out,
    "reasoning_tokens": 0,
    "cache_read_tokens": int(u.get("cache_read_tokens") or 0),
    "cache_write_tokens": int(u.get("cache_write_tokens") or 0),
    "total_tokens": inp + out,
}, sys.stdout, indent=2)
' "$WORK" > "$RUN_DIR/tokens/review_independent.json" 2>/dev/null || true

# ── verdict ──────────────────────────────────────────────────────────
TRANSPORT="$TRANSPORT" ACTUAL_MODEL="$ACTUAL_MODEL" python3 -c '
import json, os, pathlib, re, sys

raw = pathlib.Path(sys.argv[1])
transport = os.environ["TRANSPORT"]
model = os.environ["ACTUAL_MODEL"]
# True only when a genuinely different model family answered. The
# synthesizer weights an independent opinion differently from a second
# Opus 5, so this must not be fudged.
independent = transport == "antigravity"

if transport in ("none", "antigravity-failed", "claude-code-failed"):
    json.dump({"available": False, "skipped": True,
               "reviewer": "independent", "model": model,
               "transport": transport, "independent_family": False,
               "verdict": "unavailable", "blocking_issues": [],
               "notes": f"Independent review SKIPPED: {transport}"}, sys.stdout)
    raise SystemExit(0)

text = raw.read_text().strip() if raw.exists() else ""
cleaned = re.sub(r"^```(?:json)?|```$", "", text, flags=re.M).strip()
parsed = None
try:
    parsed = json.loads(cleaned)
except json.JSONDecodeError:
    m = re.search(r"\{.*\}", cleaned, re.S)
    if m:
        try:
            parsed = json.loads(m.group(0))
        except json.JSONDecodeError:
            parsed = None

base = {"available": True, "skipped": False, "reviewer": "independent",
        "model": model, "transport": transport,
        "independent_family": independent}

if parsed is None:
    base.update({"verdict": "revise",
                 "blocking_issues": ["reviewer returned unparseable output"],
                 "notes": text[:4000]})
else:
    base.update({"verdict": parsed.get("verdict", "revise"),
                 "blocking_issues": parsed.get("blocking_issues", []),
                 "notes": parsed.get("notes", "")})
json.dump(base, sys.stdout)
' "$RAW"
