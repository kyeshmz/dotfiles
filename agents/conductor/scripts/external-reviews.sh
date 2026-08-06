#!/usr/bin/env bash
# The two non-Conductor plan reviewers, run concurrently.
#
#   independent — antigravity (Gemini) if available, else Opus 5 via
#                 `claude -p`. NOT via opencode, deliberately: a separate
#                 binary and auth means an opencode outage cannot take out
#                 this reviewer too. Reports `independent_family` so a
#                 fallback-to-Opus is never mistaken for a real second
#                 model family.
#   code        — via opencode, read-only against the real repository. The
#                 only reviewer that can check the plan's claims against
#                 the actual code.
#
# Why one step: Conductor rejects script steps in both `parallel:` groups
# and `for_each` groups, so background jobs here are the only way to get
# concurrency. This costs wall-clock only, not independence — that comes
# from `context.mode: explicit` plus each agent's `input:` list.
#
# Either reviewer may be unavailable. That degrades the panel rather than
# killing the run, and is reported explicitly so a one- or two-way review
# is never mistaken for a full one.
#
# Env: RUN_DIR SCRIPTS_DIR REPO TASK PLAN_MARKDOWN PLAN_PATH
#      GEMINI_MODEL CODE_REVIEW_MODEL
set -uo pipefail

: "${RUN_DIR:?}" "${SCRIPTS_DIR:?}" "${REPO:?}" "${TASK:?}" "${PLAN_MARKDOWN:?}"
: "${PLAN_PATH:=}"
: "${GEMINI_MODEL:=gemini-3-pro}"
: "${CODE_REVIEW_ENGINE:=opencode}"
: "${CODE_REVIEW_MODEL:=parley/openai/gpt-5.6-terra}"

WORK="$RUN_DIR/reviews"
mkdir -p "$WORK/gemini" "$WORK/code" "$RUN_DIR/tokens"

cat > "$WORK/code/prompt.txt" <<PROMPT
You are reviewing an implementation plan written by a different model. Other
reviewers are examining this same plan and cannot see your findings, nor you
theirs. Do not hedge toward a consensus you cannot observe.

You are the ONLY reviewer that can read the repository. Ground your review in
what is actually there: do the referenced files, functions, and modules
exist? Does the plan assume structure the repo does not have? Spend your
effort there — it is your unique contribution. Do not modify anything.

The plan is executed one phase at a time by a single implementer that sees
only the plan file plus a per-phase dispatch. It cannot ask questions.

Review in priority order:
1. GROUNDING — do the plan's claims about this codebase hold up? Every path
   tagged [MODIFY] or [DELETE] must already exist; every path tagged [NEW]
   must not. Every symbol the plan says a file contains must be in it.
2. PHASE BOUNDARIES — each phase must leave the tree compiling with existing
   tests passing. Does any phase change a symbol whose consumers are only
   updated in a later phase? Is any file created and never wired in?
3. CORRECTNESS — will this accomplish the task?
4. VERIFICATION — is every automated-verification line a literal command
   that exists in this repository and exits non-zero when the phase failed?

Respond with ONLY a JSON object, no prose and no code fences:
{"verdict":"approved|revise|reject","blocking_issues":["..."],"notes":"..."}

Repository: ${REPO}

Plan path: ${PLAN_PATH}

Original task:
${TASK}

Proposed plan:
${PLAN_MARKDOWN}
PROMPT

export RUN_DIR REPO TASK PLAN_MARKDOWN PLAN_PATH GEMINI_MODEL
export ANTIGRAVITY_BIN="${ANTIGRAVITY_BIN:-antigravity}"
export FALLBACK_MODEL="${FALLBACK_MODEL:-claude-opus-5}"

"$SCRIPTS_DIR/gemini-review.sh" > "$WORK/gemini.json" 2>"$WORK/gemini.err" &
GEMINI_PID=$!

ENGINE="$CODE_REVIEW_ENGINE" MODEL="$CODE_REVIEW_MODEL" \
  "$SCRIPTS_DIR/agent-run.sh" review_code \
  "$WORK/code/prompt.txt" "$WORK/code" > /dev/null 2>"$WORK/code.err" &
CODE_PID=$!

GEMINI_STATUS=0; CODE_STATUS=0
wait "$GEMINI_PID" || GEMINI_STATUS=$?
wait "$CODE_PID"   || CODE_STATUS=$?

CODE_STATUS="$CODE_STATUS" CODE_REVIEW_MODEL="$CODE_REVIEW_MODEL" python3 -c '
import json, os, pathlib, re, sys

work = pathlib.Path(os.environ["RUN_DIR"]) / "reviews"
tokens = pathlib.Path(os.environ["RUN_DIR"]) / "tokens"

# Gemini writes its own verdict JSON (it owns its transport).
def load_gemini():
    p = work / "gemini.json"
    if p.exists() and p.read_text().strip():
        try:
            return json.loads(p.read_text())
        except json.JSONDecodeError:
            pass
    return {"available": False, "skipped": True, "reviewer": "independent",
            "independent_family": False,
            "verdict": "unavailable", "blocking_issues": [],
            "notes": "independent reviewer produced no parseable output"}

# The code reviewer goes through agent-run.sh, so its text is in last.txt.
def load_code():
    status = int(os.environ["CODE_STATUS"])
    model = os.environ["CODE_REVIEW_MODEL"]
    last = work / "code" / "last.txt"
    errs = []
    tf = tokens / "review_code.json"
    if tf.exists():
        try:
            errs = json.loads(tf.read_text()).get("errors", [])
        except json.JSONDecodeError:
            pass
    if status != 0 or not last.exists() or not last.read_text().strip():
        reason = "; ".join(dict.fromkeys(errs)) or f"exit {status}"
        return {"available": False, "skipped": True, "reviewer": "code-model",
                "model": model, "verdict": "unavailable",
                "blocking_issues": [],
                "notes": f"code-model review SKIPPED: {reason}"}
    text = last.read_text().strip()
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
    if parsed is None:
        return {"available": True, "skipped": False, "reviewer": "code-model",
                "model": model, "verdict": "revise",
                "blocking_issues": ["code-model returned unparseable output"],
                "notes": text[:4000]}
    return {"available": True, "skipped": False, "reviewer": "code-model",
            "model": model,
            "verdict": parsed.get("verdict", "revise"),
            "blocking_issues": parsed.get("blocking_issues", []),
            "notes": parsed.get("notes", "")}

independent, code = load_gemini(), load_code()
json.dump({
    "independent": independent,
    "code": code,
    "reviewers_available": [
        r["reviewer"] for r in (independent, code) if r.get("available")
    ],
    "reviewers_missing": [
        r["reviewer"] for r in (independent, code) if not r.get("available")
    ],
    # Explicit so the synthesizer cannot silently treat a fallback-to-Opus
    # as a genuine cross-family second opinion.
    "independent_family_present": bool(independent.get("independent_family")),
    "independent_transport": independent.get("transport", "unknown"),
}, sys.stdout)
'
